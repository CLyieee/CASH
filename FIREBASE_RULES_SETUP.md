# Firebase Security Rules Setup

This document explains how to deploy and configure Firebase security rules for your CASH app.

## Overview

Your app uses two types of Firebase security rules:

1. **Firestore Rules** (`firestore.rules`) - Secures your database
2. **Storage Rules** (`storage.rules`) - Secures file uploads/backups

## Security Features

### Firestore Rules
- ✅ Users can only read/write their own data
- ✅ Transactions are isolated per user
- ✅ Data validation on create (required fields, types)
- ✅ Amount must be positive number
- ✅ Transaction type must be 'Cash In' or 'Cash Out'
- ✅ Users cannot change userId on existing transactions
- ✅ All other collections are denied by default

### Storage Rules
- ✅ Users can only access their own backups
- ✅ Backup files limited to 50MB
- ✅ Only JSON backup files allowed
- ✅ Receipt images limited to 10MB (future feature)
- ✅ Only image files allowed for receipts
- ✅ All other paths are denied

## Deployment

### Option 1: Using the Deployment Script (Recommended)

**Windows:**
```bash
deploy_rules.bat
```

**Linux/Mac:**
```bash
chmod +x deploy_rules.sh
./deploy_rules.sh
```

### Option 2: Manual Deployment

1. Install Firebase CLI (if not installed):
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

3. Initialize Firebase (first time only):
```bash
firebase init
```
- Select "Firestore" and "Storage"
- Choose your existing project
- Accept default files (firestore.rules and storage.rules)

4. Deploy rules:
```bash
# Deploy both rules
firebase deploy --only firestore:rules,storage:rules

# Or deploy individually
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

## Verify Deployment

After deployment, verify in Firebase Console:

1. **Firestore Rules**: https://console.firebase.google.com/project/cashg-2b54c/firestore/rules
2. **Storage Rules**: https://console.firebase.google.com/project/cashg-2b54c/storage/rules

## Testing

### Test Firestore Rules

The rules enforce:
- Authentication required
- Users can only access their own data
- Data validation on creation

### Test Storage Rules

The rules enforce:
- Authentication required
- Users can only access backups in their own folder
- File size limits (50MB for backups, 10MB for images)
- File type validation

## Troubleshooting

### Error: "Object does not exist at location"
**Solution**: Deploy storage rules using the deployment script above.

### Error: "Permission denied"
**Cause**: User trying to access another user's data
**Solution**: This is expected behavior - rules are working correctly

### Error: "Missing or insufficient permissions"
**Cause**: Rules not deployed or user not authenticated
**Solution**: 
1. Deploy rules using the script
2. Ensure user is logged in

## File Structure

```
your-project/
├── firestore.rules       # Firestore security rules
├── storage.rules         # Storage security rules
├── firebase.json         # Firebase configuration
├── deploy_rules.bat      # Windows deployment script
└── deploy_rules.sh       # Linux/Mac deployment script
```

## Important Notes

1. **Always test rules** after deployment in Firebase Console
2. **Never disable authentication** - all rules require `request.auth != null`
3. **Keep rules updated** when adding new features
4. **Monitor usage** in Firebase Console for suspicious activity
5. **Backup your rules** - they're included in your git repository

## Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Review the rules files for syntax errors
3. Ensure Firebase CLI is up to date: `npm update -g firebase-tools`
4. Check Firebase documentation: https://firebase.google.com/docs/rules

## Security Best Practices

✅ **DO:**
- Keep authentication required for all operations
- Validate data types and required fields
- Limit file sizes for uploads
- Use helper functions for complex rules
- Test rules thoroughly before production

❌ **DON'T:**
- Remove authentication checks
- Allow unrestricted read/write access
- Skip data validation
- Ignore file size limits
- Deploy untested rules to production
