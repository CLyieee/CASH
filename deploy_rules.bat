@echo off
REM Firebase Rules Deployment Script for Windows
REM This script deploys your security rules to Firebase

echo ======================================
echo   Firebase Security Rules Deployment
echo ======================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Firebase CLI is not installed!
    echo Please install it by running: npm install -g firebase-tools
    exit /b 1
)

echo [OK] Firebase CLI is installed
echo.

REM Login check
echo Checking Firebase authentication...
firebase projects:list >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Please login to Firebase:
    firebase login
)

echo.
echo ======================================
echo   Deploying Firestore Rules
echo ======================================
firebase deploy --only firestore:rules

echo.
echo ======================================
echo   Deploying Storage Rules
echo ======================================
firebase deploy --only storage:rules

echo.
echo ======================================
echo   [OK] Deployment Complete!
echo ======================================
echo.
echo Your Firebase security rules have been deployed.
echo Firestore Rules: firestore.rules
echo Storage Rules: storage.rules
echo.

pause
