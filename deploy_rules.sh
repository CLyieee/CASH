#!/bin/bash

# Firebase Rules Deployment Script
# This script deploys your security rules to Firebase

echo "======================================"
echo "  Firebase Security Rules Deployment"
echo "======================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null
then
    echo "❌ Firebase CLI is not installed!"
    echo "Please install it by running: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI is installed"
echo ""

# Login check
echo "Checking Firebase authentication..."
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Please login to Firebase:"
    firebase login
fi

echo ""
echo "======================================"
echo "  Deploying Firestore Rules"
echo "======================================"
firebase deploy --only firestore:rules

echo ""
echo "======================================"
echo "  Deploying Storage Rules"
echo "======================================"
firebase deploy --only storage:rules

echo ""
echo "======================================"
echo "  ✅ Deployment Complete!"
echo "======================================"
echo ""
echo "Your Firebase security rules have been deployed."
echo "Firestore Rules: firestore.rules"
echo "Storage Rules: storage.rules"
echo ""
