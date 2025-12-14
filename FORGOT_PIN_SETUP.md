# Forgot PIN & OTP Email Setup Guide

## ✅ What's Been Implemented

### 1. OTP Service (`lib/services/otp_service.dart`)
- ✅ Generate 6-digit OTP codes
- ✅ Store OTP in Firestore with 10-minute expiration
- ✅ Verify OTP codes
- ✅ Auto-cleanup expired OTPs
- ✅ Development mode OTP display (for testing)

### 2. Forgot PIN Page (`lib/pages/forgot_pin_page.dart`)
- ✅ 3-step wizard: Request OTP → Verify OTP → Set New PIN
- ✅ Visual step indicator
- ✅ OTP input with auto-verification
- ✅ PIN confirmation with matching validation
- ✅ Neumorphic design matching app theme

### 3. Integration Points
- ✅ Login Page: "Forgot PIN?" button added
- ✅ Settings Page: "Reset PIN" option in Preferences section
- ✅ Firestore Rules: OTP collection rules added

## 🔧 Email Sending Options

Currently, the OTP is generated and stored in Firestore, but **email sending requires additional setup**. Here are your options:

### Option 1: Firebase Cloud Functions (Recommended for Production)

**Pros:**
- Fully integrated with Firebase
- Secure and scalable
- Server-side code

**Setup Steps:**

1. **Install Firebase CLI:**
```bash
npm install -g firebase-tools
firebase login
firebase init functions
```

2. **Install Nodemailer in Functions:**
```bash
cd functions
npm install nodemailer
```

3. **Create Cloud Function (functions/index.js):**
```javascript
const functions = require('firebase-functions');
const nodemailer = require('nodemailer');
const admin = require('firebase-admin');
admin.initializeApp();

// Configure email transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com',
    pass: 'your-app-password' // Use App Password, not regular password
  }
});

exports.sendOTPEmail = functions.firestore
  .document('otp_codes/{userId}')
  .onCreate(async (snap, context) => {
    const otpData = snap.data();
    const userId = context.params.userId;
    
    const mailOptions = {
      from: 'GCash Receipt Tracker <your-email@gmail.com>',
      to: otpData.email,
      subject: 'Reset Your PIN - GCash Receipt Tracker',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #64B5F6;">Reset Your PIN</h2>
          <p>Your OTP code is:</p>
          <h1 style="color: #2C3E50; font-size: 32px; letter-spacing: 5px;">${otpData.otp}</h1>
          <p>This code will expire in 10 minutes.</p>
          <p style="color: #E53935;"><strong>Do not share this code with anyone.</strong></p>
          <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
          <p style="color: #666; font-size: 12px;">
            If you didn't request this code, please ignore this email.
          </p>
        </div>
      `
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log('OTP email sent to:', otpData.email);
    } catch (error) {
      console.error('Error sending email:', error);
    }
  });
```

4. **Deploy Functions:**
```bash
firebase deploy --only functions
```

5. **Gmail App Password Setup:**
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate app password for "Mail"
   - Use this password in the Cloud Function

### Option 2: SendGrid (Alternative Email Service)

**Pros:**
- Free tier: 100 emails/day
- Easy to integrate
- Reliable delivery

**Setup Steps:**

1. **Sign up at sendgrid.com and get API key**

2. **Add SendGrid to Cloud Function:**
```bash
npm install @sendgrid/mail
```

3. **Update Cloud Function:**
```javascript
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey('your-sendgrid-api-key');

exports.sendOTPEmail = functions.firestore
  .document('otp_codes/{userId}')
  .onCreate(async (snap, context) => {
    const otpData = snap.data();
    
    const msg = {
      to: otpData.email,
      from: 'noreply@yourdomain.com', // Use verified sender
      subject: 'Reset Your PIN',
      html: `Your OTP is: <strong>${otpData.otp}</strong>`
    };

    try {
      await sgMail.send(msg);
      console.log('Email sent');
    } catch (error) {
      console.error('Error:', error);
    }
  });
```

### Option 3: Firebase Extensions (Easiest)

**Pros:**
- No code required
- Pre-built solution
- Easy to configure

**Setup Steps:**

1. **Go to Firebase Console → Extensions**
2. **Install "Trigger Email" extension**
3. **Configure SMTP settings or SendGrid**
4. **Create email template:**
   - Template name: `otp-email`
   - Subject: `Reset Your PIN`
   - Body: Use `{{otp}}` placeholder

## 📱 Testing in Development

For testing without email setup:

1. **Check Console Logs:**
   The OTP will be printed to console when generated:
   ```
   DEBUG: OTP for testing: 123456
   ```

2. **Debug Snackbar:**
   In development mode, a snackbar shows the OTP for 10 seconds

3. **Firestore Console:**
   Check the `otp_codes` collection in Firebase Console to see the generated OTP

## 🔐 Security Best Practices

1. **Never expose email credentials in client code**
   - Always use Cloud Functions for email sending
   - Store credentials in Firebase Functions config

2. **Rate limiting:**
   Add rate limiting to prevent OTP spam:
   ```javascript
   // In Cloud Function
   const recentOTPs = await admin.firestore()
     .collection('otp_codes')
     .where('email', '==', email)
     .where('createdAt', '>', new Date(Date.now() - 60000))
     .get();
   
   if (recentOTPs.size > 3) {
     throw new functions.https.HttpsError(
       'resource-exhausted',
       'Too many OTP requests. Please try again later.'
     );
   }
   ```

3. **OTP Expiration:**
   - Current: 10 minutes (good balance)
   - Can be adjusted in `otp_service.dart`

4. **Firestore Rules:**
   - Already configured to prevent unauthorized access
   - Users can only read/write their own OTP codes

## 🚀 Deployment Checklist

- [ ] Choose email service (Cloud Functions, SendGrid, or Extension)
- [ ] Set up email credentials securely
- [ ] Deploy Cloud Functions (if using Option 1 or 2)
- [ ] Deploy Firestore Rules: `firebase deploy --only firestore:rules`
- [ ] Test OTP generation and email delivery
- [ ] Remove debug OTP display from production build
- [ ] Set up email templates with branding
- [ ] Configure rate limiting
- [ ] Monitor email delivery in Firebase Console

## 🎯 User Flow

1. User taps "Forgot PIN?" on login page or "Reset PIN" in settings
2. App shows email address (from Google Sign-In)
3. User taps "Send OTP"
4. OTP is generated and stored in Firestore
5. Cloud Function triggers and sends email
6. User enters 6-digit OTP
7. App verifies OTP against Firestore
8. User sets new 4-digit PIN
9. PIN is updated in Firestore via AppController
10. User redirected to login page

## 📝 Important Notes

- **Email sending requires backend setup** - Firebase doesn't allow direct email sending from Flutter for security reasons
- **Current implementation works without email** - OTP is displayed in console/snackbar for testing
- **Production deployment needs Cloud Functions or SendGrid** - Choose based on your needs
- **Gmail App Passwords** - If using Gmail, must enable 2FA and generate app password
- **Cost** - Firebase Cloud Functions free tier: 125K invocations/month

## 🔧 Troubleshooting

**OTP not received:**
- Check Cloud Function logs in Firebase Console
- Verify email credentials are correct
- Check spam folder
- Ensure Firestore trigger is deployed

**"Invalid OTP" error:**
- OTP expires after 10 minutes
- OTP can only be used once
- Check Firestore `otp_codes` collection for stored OTP

**Email formatting issues:**
- Use HTML email templates
- Test with different email clients
- Consider using email template services

## 🎨 Customization

**Change OTP length:**
```dart
// In otp_service.dart
String generateOTP() {
  final random = Random();
  return (1000 + random.nextInt(9000)).toString(); // 4-digit
}
```

**Change expiration time:**
```dart
// In otp_service.dart
final expiryTime = DateTime.now().add(const Duration(minutes: 15)); // 15 minutes
```

**Customize email template:**
- Update Cloud Function HTML
- Add logo and branding
- Include support email/link

## ✅ Ready to Use!

Your forgot PIN feature is now:
- ✅ Fully integrated with app UI
- ✅ Secured with Firestore rules
- ✅ Ready for testing (console/snackbar OTP)
- 🔶 Needs email service setup for production

Choose an email option above and deploy to complete the setup!
