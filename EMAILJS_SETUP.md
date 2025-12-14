# EmailJS Setup Guide - Free Email Sending

## 📧 Setup (5 minutes)

### Step 1: Create EmailJS Account

1. Go to https://www.emailjs.com
2. Click **"Sign Up"** (Free forever - 200 emails/month)
3. Verify your email

### Step 2: Add Email Service

1. In EmailJS Dashboard, go to **"Email Services"**
2. Click **"Add New Service"**
3. Choose **Gmail** (or any provider you prefer)
4. Click **"Connect Account"**
5. Authorize with your Gmail
6. **Copy the Service ID** (looks like: `service_abc123`)

### Step 3: Create Email Template

1. Go to **"Email Templates"**
2. Click **"Create New Template"**
3. **Template Settings:**
   - Template Name: `OTP Reset PIN`
   - Subject: `🔒 Reset Your PIN - Verification Code`

4. **Email Content (paste this):**

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
    .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, #64B5F6 0%, #42A5F5 100%); padding: 40px 20px; text-align: center; color: white; }
    .header h1 { margin: 0; font-size: 28px; }
    .content { padding: 40px 30px; }
    .otp-box { background: #E3F2FD; border: 2px solid #64B5F6; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0; }
    .otp-code { font-size: 48px; font-weight: bold; color: #2C3E50; letter-spacing: 8px; font-family: monospace; }
    .footer { background: #f5f5f5; padding: 20px; text-align: center; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div style="font-size: 48px;">🔒</div>
      <h1>Reset Your PIN</h1>
    </div>
    <div class="content">
      <p style="font-size: 16px; color: #2C3E50;">Hello!</p>
      <p style="font-size: 16px; color: #2C3E50;">You've requested to reset your PIN for <strong>{{app_name}}</strong>.</p>
      <p style="font-size: 16px; color: #2C3E50;">Use this verification code:</p>
      
      <div class="otp-box">
        <div style="color: #64B5F6; font-size: 14px; font-weight: 600; margin-bottom: 10px;">YOUR VERIFICATION CODE</div>
        <div class="otp-code">{{otp_code}}</div>
        <p style="color: #666; font-size: 13px; margin-top: 15px;">⏰ Valid for {{expiry_minutes}} minutes</p>
      </div>
      
      <div style="background: #FFF3E0; border-left: 4px solid #FF9800; padding: 15px; border-radius: 4px; margin: 20px 0;">
        <p style="color: #E65100; font-size: 14px; margin: 0;">
          <strong>⚠️ Security Notice:</strong> Never share this code with anyone.
        </p>
      </div>
      
      <p style="font-size: 14px; color: #666; margin-top: 30px;">
        If you didn't request this, please ignore this email.
      </p>
    </div>
    <div class="footer">
      <p>This is an automated message from <strong>GCash Receipt Tracker</strong>.</p>
      <p>© 2025 GCash Receipt Tracker</p>
    </div>
  </div>
</body>
</html>
```

5. **IMPORTANT: Configure Template Settings:**
   - Click **"Settings"** tab in the template editor
   - Set **"To Email"** field to: `{{to_email}}`
   - Set **"Reply To"** (optional): `{{reply_to}}`
   - Set **"From Name"**: `GCash Receipt Tracker`

6. **Template Variables used:**
   - `{{to_email}}` - Recipient email (REQUIRED in Settings → To Email)
   - `{{otp_code}}` - The OTP code
   - `{{app_name}}` - App name
   - `{{expiry_minutes}}` - Expiry time

7. **Test the template (IMPORTANT!):**
   - Click **"Test It"** button in the template editor
   - Fill in sample values:
     - `to_email`: your email
     - `otp_code`: `123456`
     - `app_name`: `GCash Receipt Tracker`
     - `expiry_minutes`: `10`
   - Click **"Send Test"**
   - Check your email - the OTP should show "123456"
   - If OTP is blank, the variables aren't set up correctly

8. Click **"Save"**
9. **Copy the Template ID** (looks like: `template_xyz789`)

### Step 4: Get Public Key

1. Go to **"Account"** → **"General"**
2. Find **"Public Key"** section
3. **Copy the Public Key** (looks like: `pUbL1cK3y_aBc123`)

### Step 5: Update Your App

Open `lib/services/otp_service.dart` and update these lines:

```dart
// EmailJS Configuration - Get these from https://dashboard.emailjs.com
static const String _emailJsServiceId = 'service_abc123';      // Step 2
static const String _emailJsTemplateId = 'template_xyz789';    // Step 3
static const String _emailJsPublicKey = 'pUbL1cK3y_aBc123';    // Step 4
```

### Step 6: Test It!

1. Run your app: `flutter run`
2. Tap "Forgot PIN?"
3. Tap "Send OTP"
4. **Check your email inbox** 📬
5. Enter the OTP code

## ✅ Done!

Your app now sends real emails for FREE! 

## 📊 Free Tier Limits

- **200 emails/month** - FREE forever
- **No credit card required**
- **Reliable delivery**
- **50KB per email**

## 🔧 Troubleshooting

### "412 - Insufficient authentication scopes" ⚠️
**This is the most common error!** Your Gmail needs proper permissions.

**Fix:**
1. Go to EmailJS Dashboard → **"Email Services"**
2. Find your Gmail service
3. Click **"Reconnect"** or **"Edit"**
4. Click **"Authorize with Google"**
5. **IMPORTANT:** When Google asks for permissions:
   - ✅ Check **"Send email on your behalf"**
   - ✅ Check **"View your email address"**
   - ✅ Grant ALL requested permissions
6. Click **"Allow"**
7. Test again in your app

**Alternative (if above doesn't work):**
1. Delete the Gmail service in EmailJS
2. Add it again from scratch
3. Make sure to grant ALL permissions when authorizing

### "422 - Recipients address is empty"
- Make sure you configured the template **Settings** tab
- Set **"To Email"** field to: `{{to_email}}`
- This is different from the HTML template content

### "Email not received"
- Check spam folder
- Verify the email address is correct
- Check EmailJS dashboard logs
- Make sure you copied all 3 IDs correctly

### "400 Bad Request"
- Double-check Service ID, Template ID, and Public Key
- Make sure template variables match (`{{otp_code}}`, etc.)
- Check EmailJS dashboard → Logs for details

### "Gmail authorization failed"
- Re-connect your Gmail in EmailJS dashboard
- Make sure "Less secure apps" is enabled (if using old Gmail)
- Try using Gmail App Password instead

### Check Logs
- EmailJS Dashboard → **"Email Logs"**
- See all sent emails and any errors

## 💡 Tips

**Test email template:**
1. EmailJS Dashboard → Email Templates
2. Click your template
3. Click **"Test It"**
4. Fill in sample data
5. Send to your email

**Monitor usage:**
- Dashboard shows emails sent this month
- Get notified at 80% and 100% usage

**Upgrade if needed:**
- $7/month = 1,000 emails
- $15/month = 5,000 emails

## 🎉 Success!

You now have a professional email system without:
- ❌ Paid Firebase plan
- ❌ Backend servers
- ❌ Complex setup

Just **3 IDs** and you're done! 🚀
