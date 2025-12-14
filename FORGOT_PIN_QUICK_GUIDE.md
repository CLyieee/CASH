# Forgot PIN Feature - Quick Reference

## 🎯 What's New

You now have a complete "Forgot PIN" feature with OTP email verification!

## 📍 Access Points

### 1. Login Page
- **Location:** After PIN entry dots
- **Button:** "Forgot PIN?" text button
- **Action:** Opens forgot PIN wizard

### 2. Settings Page
- **Section:** Preferences (after Biometric login)
- **Option:** "Reset PIN" with lock icon
- **Action:** Opens forgot PIN wizard

## 🔄 Reset Flow

```
1. Request OTP
   ↓
   User sees their Google email
   ↓
   Taps "Send OTP"
   ↓
   OTP generated & stored in Firestore

2. Verify OTP
   ↓
   User enters 6-digit code
   ↓
   Code verified against Firestore
   ↓
   Can resend if needed

3. Set New PIN
   ↓
   User enters 4-digit PIN
   ↓
   Confirms PIN
   ↓
   PIN updated in Firestore
   ↓
   Redirects to login
```

## 🧪 Testing (Development Mode)

**Without Email Setup:**
1. Tap "Forgot PIN?"
2. Tap "Send OTP"
3. Check console output for OTP: `DEBUG: OTP for testing: 123456`
4. Orange snackbar also shows OTP for 10 seconds
5. Enter the 6-digit OTP
6. Set new 4-digit PIN

**The OTP is also stored in Firestore:**
- Collection: `otp_codes`
- Document ID: user's UID
- Fields: `otp`, `email`, `expiryTime`, `used`

## 📧 Production Setup Needed

For production, you need to set up email sending:

**Option 1: Firebase Cloud Functions** (Recommended)
- See [FORGOT_PIN_SETUP.md](FORGOT_PIN_SETUP.md) for full guide
- Uses Nodemailer with Gmail/SMTP
- Free tier: 125K emails/month

**Option 2: SendGrid**
- 100 emails/day free
- Easy integration
- Reliable delivery

**Option 3: Firebase Extensions**
- No code required
- Pre-built "Trigger Email" extension
- Configure in Firebase Console

## 🔐 Security Features

✅ OTP expires after 10 minutes  
✅ OTP can only be used once  
✅ Firestore rules prevent unauthorized access  
✅ User can only reset their own PIN  
✅ OTP sent to verified Google Sign-In email  

## 📝 Important Files

```
New Files:
├── lib/services/otp_service.dart          # OTP generation & verification
├── lib/pages/forgot_pin_page.dart         # 3-step reset wizard
└── FORGOT_PIN_SETUP.md                    # Email setup guide

Modified Files:
├── lib/pages/login_page.dart              # Added "Forgot PIN?" button
├── lib/pages/settings_page.dart           # Added "Reset PIN" option
└── firestore.rules                        # Added OTP collection rules
```

## 🎨 UI Features

- **Neumorphic design** matching app theme
- **3-step progress indicator** shows current step
- **Animated transitions** between steps
- **Auto-verification** when OTP/PIN complete
- **Resend OTP** option available
- **Clear error messages** for invalid codes

## ⚙️ Configuration

**Change OTP expiration time:**
```dart
// In lib/services/otp_service.dart, line ~15
final expiryTime = DateTime.now().add(const Duration(minutes: 10));
// Change to: Duration(minutes: 15) for 15 minutes
```

**Change OTP length:**
```dart
// In lib/services/otp_service.dart, line ~11
return (100000 + random.nextInt(900000)).toString(); // 6 digits
// For 4 digits: (1000 + random.nextInt(9000)).toString()
```

## 🚀 Next Steps

1. **Test the feature** in development mode
2. **Choose an email service** (Cloud Functions, SendGrid, or Extension)
3. **Set up email sending** using [FORGOT_PIN_SETUP.md](FORGOT_PIN_SETUP.md)
4. **Deploy Firestore rules**: `firebase deploy --only firestore:rules`
5. **Remove debug OTP display** before production release

## 🐛 Troubleshooting

**"Please sign in with Google first" error:**
- User must be logged in with Google to use forgot PIN
- Email comes from their Google Sign-In account

**"Invalid OTP" error:**
- OTP expired (10 min limit)
- OTP already used
- Wrong code entered

**OTP not in console:**
- Check that OTP service is generating codes
- Look in Firestore Console → `otp_codes` collection

## 📞 Support

For email setup questions, see the detailed guide:
[FORGOT_PIN_SETUP.md](FORGOT_PIN_SETUP.md)

---

**Status:** ✅ Fully implemented and ready for testing!  
**Email:** 🔶 Needs production setup (works in dev with console logs)
