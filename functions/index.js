const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');

// Initialize Firebase Admin
admin.initializeApp();

// Twilio credentials - set these as environment variables in Firebase Console
// Run: firebase functions:config:set twilio.account_sid="YOUR_SID" twilio.auth_token="YOUR_TOKEN" twilio.phone_number="+1XXXXXXXXXX"
let TWILIO_ACCOUNT_SID = functions.config().twilio?.account_sid;
let TWILIO_AUTH_TOKEN = functions.config().twilio?.auth_token;
let TWILIO_PHONE_NUMBER = functions.config().twilio?.phone_number;

// Fallback to environment variables if not set via Firebase config
if (!TWILIO_ACCOUNT_SID) TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID;
if (!TWILIO_AUTH_TOKEN) TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN;
if (!TWILIO_PHONE_NUMBER) TWILIO_PHONE_NUMBER = process.env.TWILIO_PHONE_NUMBER;

console.log('🔐 Twilio Configuration:');
console.log(`   Account SID: ${TWILIO_ACCOUNT_SID ? '✅ Set' : '❌ Missing'}`);
console.log(`   Auth Token: ${TWILIO_AUTH_TOKEN ? '✅ Set' : '❌ Missing'}`);
console.log(`   Phone Number: ${TWILIO_PHONE_NUMBER || '❌ Missing'}`);


/**
 * Get fresh Twilio client with current credentials
 * This ensures we always use up-to-date config settings (not stale module-level instance)
 */
function getTwilioClient() {
  return twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);
}

/**
 * Format phone number to E.164 format for Twilio
 * @param {string} phoneNumber - Raw phone number
 * @param {string} countryCode - Country code (e.g., '+1', '+92', '+44')
 * @returns {string} Formatted phone number in E.164 format
 */
function formatPhoneForTwilio(phoneNumber, countryCode = '+1') {
  // Trim and clean whitespace
  phoneNumber = phoneNumber.trim();
  
  // Remove all formatting characters: spaces, dashes, parentheses, dots, commas
  phoneNumber = phoneNumber.replace(/[\s\-\(\)\.,]/g, '');
  
  console.log(`   Raw phone after cleaning: ${phoneNumber}`);
  
  // If already has country code, validate and return
  if (phoneNumber.startsWith('+')) {
    console.log(`   Phone already has country code: ${phoneNumber}`);
    return phoneNumber;
  }
  
  // If starts with 0, remove it (common in some countries)
  if (phoneNumber.startsWith('0')) {
    console.log(`   Removing leading 0 from: ${phoneNumber}`);
    phoneNumber = phoneNumber.substring(1);
  }
  
  // Extract country code number (remove the +)
  const countryCodeNumber = countryCode.replace('+', '');
  
  // Add country code
  const formatted = '+' + countryCodeNumber + phoneNumber;
  console.log(`   Formatted to E.164: ${formatted}`);
  
  return formatted;
}

/**
 * Validate phone number in E.164 format
 * @param {string} phoneNumber - Phone number to validate
 * @returns {boolean} True if valid E.164 format
 */
function isValidPhoneNumber(phoneNumber) {
  // E.164 format: +[1-9]{1,3}[0-9]{4,14}
  // More flexible to handle various phone lengths
  const e164Regex = /^\+[1-9]\d{4,14}$/;
  
  const isValid = e164Regex.test(phoneNumber);
  console.log(`   Validating: ${phoneNumber} → ${isValid ? '✅ Valid' : '❌ Invalid'}`);
  
  return isValid;
}


/**
 * Cloud Function: sendSosAlert
 * Sends SMS to emergency contacts when SOS is triggered
 * 
 * Expected data:
 * {
 *   userId: string,
 *   userName: string,
 *   latitude: number,
 *   longitude: number,
 *   emergencyContacts: Array<{name: string, phone: string}>
 * }
 */
exports.sendSosAlert = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).send('');
    return;
  }

  const { userId, userName, latitude, longitude } = req.body;

  console.log('📥 Received request:');
  console.log('  userId:', userId);
  console.log('  userName:', userName);
  console.log('  latitude:', latitude);
  console.log('  longitude:', longitude);

  // Validate required fields
  if (!userId || !userName || !latitude || !longitude) {
    res.status(400).json({
      error: 'Missing required fields: userId, userName, latitude, longitude'
    });
    return;
  }

  // Validate Twilio credentials
  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_PHONE_NUMBER) {
    console.error('❌ Twilio credentials not configured');
    console.error(`   Account SID: ${TWILIO_ACCOUNT_SID ? '✅' : '❌ Missing'}`);
    console.error(`   Auth Token: ${TWILIO_AUTH_TOKEN ? '✅' : '❌ Missing'}`);
    console.error(`   Phone Number: ${TWILIO_PHONE_NUMBER ? '✅' : '❌ Missing'}`);
    res.status(500).json({
      error: 'SMS service not configured. Please set Twilio credentials.',
      details: 'Run: firebase functions:config:set twilio.account_sid="YOUR_SID" twilio.auth_token="YOUR_TOKEN"'
    });
    return;
  }

  try {
    // Fetch emergency contacts from Firestore
    console.log('📞 Fetching emergency contacts from Firestore for userId:', userId);
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) {
      console.warn('⚠️ User document not found');
      res.status(400).json({
        error: 'User not found'
      });
      return;
    }

    const userData = userDoc.data();
    console.log('👤 User data retrieved:', JSON.stringify(userData, null, 2));
    
    const emergencyContacts = userData?.emergencyContacts || [];

    console.log('📞 Found emergency contacts:', JSON.stringify(emergencyContacts, null, 2));
    console.log('📞 Number of contacts:', emergencyContacts.length);
    console.log('📞 Is array:', Array.isArray(emergencyContacts));

    if (!Array.isArray(emergencyContacts) || emergencyContacts.length === 0) {
      console.warn('⚠️ No emergency contacts found');
      res.status(400).json({
        error: 'No emergency contacts configured'
      });
      return;
    }

    // Generate Google Maps link
    const mapsLink = `https://maps.google.com/?q=${latitude},${longitude}`;

    // Prepare SMS message
    const smsMessage = `Your Contact ${userName} is in an emergency situation and has triggered SOS.\n\n📍 Live Location: ${mapsLink}`;

    console.log(`📱 Sending SOS alert from ${userName} to ${emergencyContacts.length} contacts`);

    const results = {
      successful: [],
      failed: [],
    };

    // Send SMS to each emergency contact
    for (const contact of emergencyContacts) {
      try {
        let phoneNumber = contact.phone;
        const contactName = contact.name;
        const countryCode = contact.countryCode || '+1'; // Default to +1 (US/Canada)

        if (!phoneNumber) {
          console.warn(`⚠️ Contact ${contactName} has no phone number, skipping`);
          results.failed.push({
            name: contactName,
            phone: phoneNumber,
            error: 'No phone number',
          });
          continue;
        }

        console.log(`\n📞 Processing contact: ${contactName}`);
        console.log(`   Raw phone: ${phoneNumber}`);
        console.log(`   Country code: ${countryCode}`);

        // Format phone number for Twilio (E.164 format)
        phoneNumber = formatPhoneForTwilio(phoneNumber, countryCode);

        if (!isValidPhoneNumber(phoneNumber)) {
          console.warn(`⚠️ Contact ${contactName} has invalid phone format: ${phoneNumber}, skipping`);
          results.failed.push({
            name: contactName,
            phone: phoneNumber,
            error: `Invalid phone format: ${phoneNumber}`,
          });
          continue;
        }

        console.log(`✅ Phone number valid and formatted: ${phoneNumber}`);

        // Send SMS via Twilio
        const message = await twilioClient.messages.create({
          body: smsMessage,
          from: TWILIO_PHONE_NUMBER,
          to: phoneNumber,
        });

        console.log(`✅ SMS sent to ${contactName} (${phoneNumber}): ${message.sid}`);
        results.successful.push({
          name: contactName,
          phone: phoneNumber,
          messageSid: message.sid,
        });

        // Log to Firestore for audit trail
        await admin.firestore().collection('sos_alerts').add({
          userId: userId,
          userName: userName,
          recipientName: contactName,
          recipientPhone: phoneNumber,
          latitude: latitude,
          longitude: longitude,
          messageSid: message.sid,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          status: 'sent',
        });
      } catch (error) {
        console.error(`❌ Failed to send SMS to ${contact.name}: ${error.message}`);
        results.failed.push({
          name: contact.name,
          phone: contact.phone,
          error: error.message,
        });

        // Log failed attempt to Firestore
        await admin.firestore().collection('sos_alerts').add({
          userId: userId,
          userName: userName,
          recipientName: contact.name,
          recipientPhone: contact.phone,
          latitude: latitude,
          longitude: longitude,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          status: 'failed',
          error: error.message,
        });
      }
    }

    console.log(`📊 SOS Alert Summary: ${results.successful.length} sent, ${results.failed.length} failed`);

    res.json({
      success: true,
      message: `SOS alert sent to ${results.successful.length} contacts`,
      results: results,
    });
  } catch (error) {
    console.error('❌ Error in sendSosAlert:', error);
    res.status(500).json({
      error: error.message || 'Internal server error'
    });
  }
});

/**
 * Cloud Function: testSosAlert
 * Test function to verify Twilio integration (optional)
 */
/**
 * Cloud Function: debugEmergencyContacts
 * Debug endpoint to check what emergency contacts are stored in Firestore
 */
exports.debugEmergencyContacts = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).send('');
    return;
  }

  const { userId } = req.body;

  if (!userId) {
    res.status(400).json({
      error: 'userId is required'
    });
    return;
  }

  try {
    console.log('🔍 Debug: Fetching user data for userId:', userId);
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) {
      console.warn('⚠️ User document not found');
      res.status(404).json({
        error: 'User not found',
        userId: userId
      });
      return;
    }

    const userData = userDoc.data();
    console.log('👤 Full user data:', JSON.stringify(userData, null, 2));

    const emergencyContacts = userData?.emergencyContacts || [];

    res.json({
      success: true,
      userId: userId,
      userData: userData,
      emergencyContacts: emergencyContacts,
      contactCount: emergencyContacts.length,
      isArray: Array.isArray(emergencyContacts),
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('❌ Debug error:', error);
    res.status(500).json({
      error: error.message,
      userId: userId
    });
  }
});

/**
 * Cloud Function: testTwilioCredentials
 * Test if Twilio credentials are valid (no manual verification needed)
 */
exports.testTwilioCredentials = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).send('');
    return;
  }

  try {
    console.log('🧪 Testing Twilio Credentials...');
    console.log(`   Account SID: ${TWILIO_ACCOUNT_SID ? TWILIO_ACCOUNT_SID.substring(0, 5) + '...' : 'NOT SET'}`);
    console.log(`   Auth Token: ${TWILIO_AUTH_TOKEN ? '***' + TWILIO_AUTH_TOKEN.substring(-5) : 'NOT SET'}`);
    console.log(`   Phone Number: ${TWILIO_PHONE_NUMBER}`);

    if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_PHONE_NUMBER) {
      return res.status(400).json({
        success: false,
        error: 'Twilio credentials not configured',
        details: {
          accountSid: !TWILIO_ACCOUNT_SID ? '❌ Missing' : '✅ Set',
          authToken: !TWILIO_AUTH_TOKEN ? '❌ Missing' : '✅ Set',
          phoneNumber: !TWILIO_PHONE_NUMBER ? '❌ Missing' : '✅ Set',
        },
      });
    }

    // Test: Try to access Twilio API
    console.log('📞 Attempting to fetch Twilio account info...');
    const accountInfo = await twilioClient.api.accounts.list({ limit: 1 });
    
    if (accountInfo.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Could not authenticate with Twilio',
        details: 'Credentials appear invalid or account not found',
      });
    }

    const account = accountInfo[0];

    console.log('✅ Twilio Connection Successful!');
    console.log(`   Account: ${account.friendlyName}`);
    console.log(`   Status: ${account.status}`);
    console.log(`   Type: ${account.type}`);

    res.json({
      success: true,
      message: 'Twilio credentials are valid!',
      account: {
        friendlyName: account.friendlyName,
        status: account.status,
        type: account.type,
      },
      canSendSMS: account.status === 'active',
      trialAccount: account.type === 'Trial',
      recommendation: account.type === 'Trial' 
        ? 'UPGRADE: Trial accounts can only send SMS to verified numbers. Upgrade to full account for unrestricted sending.'
        : 'Ready to send SMS to any number in the world!',
    });
  } catch (error) {
    console.error('❌ Twilio Test Failed:', error.message);
    res.status(500).json({
      success: false,
      error: `Twilio error: ${error.message}`,
      details: error.message.includes('Authenticate') 
        ? 'Invalid credentials - check Account SID and Auth Token'
        : error.message,
    });
  }
});

/**
 * Cloud Function: testSosAlert
 * Test function to verify Twilio integration (optional)
 */
exports.testSosAlert = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).send('');
    return;
  }

  const { testPhoneNumber } = req.body;

  if (!testPhoneNumber) {
    res.status(400).json({
      error: 'testPhoneNumber is required'
    });
    return;
  }

  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_PHONE_NUMBER) {
    res.status(500).json({
      error: 'SMS service not configured'
    });
    return;
  }

  try {
    const message = await twilioClient.messages.create({
      body: '🧪 Test SMS from Smart Wristband App - Twilio integration working!',
      from: TWILIO_PHONE_NUMBER,
      to: testPhoneNumber,
    });

    console.log(`✅ Test SMS sent: ${message.sid}`);

    res.json({
      success: true,
      message: 'Test SMS sent successfully',
      messageSid: message.sid,
    });
  } catch (error) {
    console.error(`❌ Test SMS failed: ${error.message}`);
    res.status(500).json({
      error: `Failed to send test SMS: ${error.message}`
    });
  }
});
