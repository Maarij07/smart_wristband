#!/bin/bash

# SOS SMS Deployment Script
# This script deploys the Twilio SMS integration for SOS alerts

set -e

echo "🚀 Starting SOS SMS Deployment..."
echo ""

# Step 1: Get Twilio credentials
echo "📝 Step 1: Configuring Twilio Credentials"
echo "================================================"
echo ""
echo "You need to provide:"
echo "1. Twilio Account SID (from https://console.twilio.com)"
echo "2. Twilio Auth Token (from https://console.twilio.com)"
echo "3. Twilio Phone Number (e.g., +1234567890)"
echo ""

read -p "Enter Twilio Account SID: " ACCOUNT_SID
read -p "Enter Twilio Auth Token: " AUTH_TOKEN
read -p "Enter Twilio Phone Number: " PHONE_NUMBER

echo ""
echo "✅ Credentials received"
echo ""

# Step 2: Set Firebase config
echo "📝 Step 2: Setting Firebase Configuration"
echo "================================================"
echo ""

cd functions

echo "Setting twilio.account_sid..."
firebase functions:config:set twilio.account_sid="$ACCOUNT_SID"

echo "Setting twilio.auth_token..."
firebase functions:config:set twilio.auth_token="$AUTH_TOKEN"

echo "Setting twilio.phone_number..."
firebase functions:config:set twilio.phone_number="$PHONE_NUMBER"

echo ""
echo "✅ Firebase configuration set"
echo ""

# Step 3: Verify configuration
echo "📝 Step 3: Verifying Configuration"
echo "================================================"
echo ""
firebase functions:config:get
echo ""
echo "✅ Configuration verified"
echo ""

# Step 4: Install dependencies
echo "📝 Step 4: Installing Dependencies"
echo "================================================"
echo ""
npm install
echo ""
echo "✅ Dependencies installed"
echo ""

# Step 5: Deploy functions
echo "📝 Step 5: Deploying Cloud Functions"
echo "================================================"
echo ""
firebase deploy --only functions
echo ""
echo "✅ Cloud Functions deployed"
echo ""

# Step 6: Update Flutter app
echo "📝 Step 6: Updating Flutter App"
echo "================================================"
echo ""
cd ..
flutter pub get
echo ""
echo "✅ Flutter dependencies updated"
echo ""

# Step 7: Summary
echo "🎉 Deployment Complete!"
echo "================================================"
echo ""
echo "✅ Cloud Functions deployed"
echo "✅ Twilio credentials configured"
echo "✅ Flutter app updated"
echo ""
echo "Next steps:"
echo "1. Add emergency contacts in the app"
echo "2. Trigger SOS from wristband"
echo "3. Enter PIN (1111)"
echo "4. Check phone for SMS"
echo ""
echo "For debugging:"
echo "  firebase functions:log"
echo ""
echo "For monitoring:"
echo "  Check Firestore collection: sos_alerts"
echo ""
