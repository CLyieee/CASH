# Firebase Cloud Functions Setup for OTP Email

## 📧 Automatic Email Sending

The Cloud Function automatically sends an email whenever an OTP is created in Firestore.

## 🚀 Quick Setup (5 Steps)

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### Step 2: Initialize Functions (if not already done)

```bash
cd C:\Users\ramil\OneDrive\Documents\Desktop\g\CASH
firebase init functions
```

Choose:
- ✅ Use existing project (select your Firebase project)
- ✅ JavaScript
- ✅ ESLint: Yes
- ✅ Install dependencies: Yes

### Step 3: Install Dependencies

```bash
cd functions
npm install
```

### Step 4: Configure Email Service

Choose **ONE** option:

#### Option A: Gmail (Easiest)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password:**
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Copy the 16-character password

3. **Update `functions/index.js`:**
   ```javascript
   const transporter = nodemailer.createTransport({
     service: 'gmail',
     auth: {
       user: 'your-email@gmail.com',      // Your Gmail
       pass: 'abcd efgh ijkl mnop'        // App Password (no spaces)
     }
   });
   ```

4. **Update sender email:**
   ```javascript
   from: 'GCash Receipt Tracker <your-email@gmail.com>',
   ```

#### Option B: SendGrid (Better for Production)

1. **Sign up:** https://sendgrid.com (Free: 100 emails/day)
2. **Get API Key:** Settings → API Keys → Create API Key
3. **Verify Sender:** Settings → Sender Authentication

4. **Install SendGrid:**
   ```bash
   npm install @sendgrid/mail
   ```

5. **Update `functions/index.js`:**
   - Uncomment SendGrid section (lines with `sgMail`)
   - Comment out Nodemailer section
   - Add your API key and verified sender email

### Step 5: Deploy

```bash
firebase deploy --only functions
```

✅ Done! Emails will now be sent automatically when OTP is requested.

## 🧪 Testing

1. In your app, tap "Forgot PIN?"
2. Tap "Send OTP"
3. Check your email inbox
4. Check Firebase Console → Functions → Logs for status

## 📊 Monitor Function Logs

```bash
firebase functions:log
```

Or check in Firebase Console:
- Functions → Dashboard → View logs

## 💰 Pricing

**Firebase Functions Free Tier:**
- 125,000 invocations/month
- 40,000 GB-seconds
- 40,000 CPU-seconds

**Gmail:**
- Free (with App Password)
- Limit: ~500 emails/day

**SendGrid:**
- Free: 100 emails/day
- Paid: Starting at $15/month for 40K emails

## 🔧 Troubleshooting

### "Gmail authentication failed"
- Make sure 2FA is enabled
- Use App Password, not regular password
- Remove spaces from App Password

### "SendGrid: Sender not verified"
- Verify sender email in SendGrid dashboard
- Use the exact verified email as sender

### "Function not triggered"
- Check Firestore collection name is `otp_codes`
- Check function deployed: `firebase functions:list`
- Check logs: `firebase functions:log`

### "Email goes to spam"
- Add SPF/DKIM records (SendGrid provides these)
- Use verified domain
- Avoid spam trigger words

## 🔐 Security Best Practices

1. **Never commit credentials** to git:
   ```bash
   # Add to .gitignore
   functions/.env
   ```

2. **Use Environment Config:**
   ```bash
   firebase functions:config:set gmail.email="your@gmail.com" gmail.password="app-password"
   ```

   Then in code:
   ```javascript
   const gmailEmail = functions.config().gmail.email;
   const gmailPassword = functions.config().gmail.password;
   ```

3. **Rate limiting** is already handled by the 10-minute expiry

## 📝 Email Template Customization

Edit `functions/index.js` to customize:

**Change colors:**
```javascript
background: linear-gradient(135deg, #YOUR_COLOR 0%, #YOUR_COLOR 100%);
```

**Add logo:**
```html
<img src="https://your-domain.com/logo.png" alt="Logo" style="width: 100px;">
```

**Change expiry time:**
In `lib/services/otp_service.dart`:
```dart
final expiryTime = DateTime.now().add(const Duration(minutes: 15));
```

## ✅ Verification

After deployment, you should see:
```
✔ functions[sendOTPEmail(us-central1)] Successful create operation.
✔ functions[cleanupExpiredOTPs(us-central1)] Successful create operation.
```

Test by requesting OTP in your app - check:
1. Firebase Console → Functions → Logs
2. Your email inbox
3. Firestore → otp_codes → emailSent field should be `true`

## 🎉 Success!

Your app now sends real OTP emails! Users will receive professional-looking emails with their verification codes.
