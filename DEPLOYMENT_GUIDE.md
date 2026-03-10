# SOS Feature Fix - Deployment Guide

## Changes Made

### 1. **Cloud Function Update** (`functions/index.js`)
- ✅ Added `formatPhoneForTwilio()` function to handle multiple country codes
- ✅ Added `isValidPhoneNumber()` function to validate E.164 format
- ✅ Updated emergency contact loop to use `countryCode` from contact data
- ✅ Removed hardcoded +92 (Pakistan) assumption

### 2. **Flutter App Update** (`lib/screens/emergency_contacts_screen.dart`)
- ✅ Added country code selector dropdown
- ✅ Updated data structure to store `countryCode` with each contact
- ✅ Modified contact display to show country code
- ✅ Default to +1 (US/Canada) for new contacts

---

## Deployment Steps

### Step 1: Deploy Updated Cloud Function

```bash
# Navigate to functions directory
cd functions

# Deploy only the sendSosAlert function
firebase deploy --only functions:sendSosAlert

# Monitor logs
firebase functions:log
```

### Step 2: Update Flutter App

1. **Pull the latest code** (emergency_contacts_screen.dart has been updated)

2. **Clean rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Or if already running:**
   - Hot reload should work: `r` key
   - If issues occur, do full rebuild: `flutter run --no-fast-start`

### Step 3: Test the Fix

#### Test 1: Add Emergency Contact with +18 Number
```
1. Go to Emergency Contacts screen
2. Select country code: "🇺🇸 US/Canada (+1)"
3. Add a contact with phone: "855-123-4567" or "+18551234567"
4. Verify it shows: "Contact (+1)" in the chip
5. Press Save
```

#### Test 2: Trigger SOS and Verify SMS Sent
```
1. Open SOS Alert screen
2. Trigger SOS (enter PIN)
3. Should show: "SOS alert sent to 1 contact" (not 0)
4. Check Twilio logs in Firebase Console
5. Verify SMS received on the phone
```

#### Test 3: Multiple Emergency Contacts
```
1. Add 3 emergency contacts with +1 country code
2. Trigger SOS
3. Should show: "SOS alert sent to 3 contacts"
4. All 3 should receive SMS
```

---

## Verify in Firebase Console

### Check Cloud Function Logs:

1. **Go to Firebase Console** → **Functions** → **sendSosAlert**
2. **Logs tab** - Look for:
   - ✅ `📱 Formatted phone number: ...` (shows country code handling)
   - ✅ `SMS sent to...` (successful sends)
   - ❌ `Invalid phone format` (if validation fails)

### Example Good Log Output:
```
📥 Received request:
  userId: abc123...
  userName: John Doe
  latitude: 40.7128
  longitude: -74.0060
📞 Fetching emergency contacts from Firestore for userId: abc123...
📞 Found emergency contacts: [
  {name: "Mom", phone: "8551234567", countryCode: "+1"},
  {name: "Sister", phone: "8559876543", countryCode: "+1"}
]
📱 Formatted phone number: 8551234567 (+1) → +18551234567
📱 Sending SOS alert from John Doe to 2 contacts
✅ SMS sent to Mom (+18551234567): SM1234567890abcdef
✅ SMS sent to Sister (+18559876543): SM0987654321fedcba
📊 SOS Alert Summary: 2 sent, 0 failed
```

### Check Twilio Logs:

1. **Go to Twilio Console** → **Logs** → **Message Logs**
2. Filter by your Twilio number: `+18556931007`
3. Verify messages show:
   - Status: `Delivered` or `Sent`
   - To: Your emergency contact numbers (+18551234567, etc.)

---

## Troubleshooting

### Issue: "SOS alert sent to 0 contacts" Still Appears

**Check 1: Verify Firestore structure**
```bash
# In Firebase Console:
# Collection: users → Your User ID → emergencyContacts field
# Should look like:
[
  {
    "name": "Mom",
    "phone": "8551234567",
    "countryCode": "+1",
    "country": "US"
  }
]
```

**Check 2: View Cloud Function logs**
```bash
firebase functions:log --region us-central1
```

Look for the actual error message from Twilio.

**Check 3: Test phone number format**

Run this in Firebase Cloud Shell:
```javascript
// Paste this in Firestore Rules playground
// Test if the phone number is valid E.164
function formatPhoneForTwilio(phoneNumber, countryCode = '+1') {
  phoneNumber = phoneNumber.trim();
  if (phoneNumber.startsWith('+')) {
    return phoneNumber;
  }
  phoneNumber = phoneNumber.replace(/[\s\-\(\)\.]/g, '');
  if (phoneNumber.startsWith('0')) {
    phoneNumber = phoneNumber.substring(1);
  }
  return countryCode + phoneNumber;
}

// Test
formatPhoneForTwilio('8551234567', '+1')  // Should return: +18551234567
```

### Issue: "Invalid phone format" Error

**Solution:**
1. Ensure phone numbers don't have extra characters
2. Format example: `8551234567` (not `(855) 123-4567`)
3. Re-save emergency contacts
4. Or manually edit in Firebase Console

### Issue: SMS Sending But Not Received

**Check Twilio Account:**
1. **SMS Balance** - Ensure account has credits
2. **Number Status** - Check if Twilio number is active
3. **Recipient Verification** - If personal account, add recipient numbers as verified

---

## Rollback (If Needed)

If something goes wrong, you can revert:

```bash
# View deployment history
firebase functions:list

# Roll back to previous version
# In Firebase Console: Functions → sendSosAlert → Revisions → Select older version
```

---

## Files Modified

| File | Changes |
|------|---------|
| `functions/index.js` | Added phone formatting functions, removed hardcoded +92 |
| `lib/screens/emergency_contacts_screen.dart` | Added country code selector, updated data structure |
| `lib/services/sos_messaging_service.dart` | No changes needed (already correct) |
| `lib/screens/sos_alert_screen.dart` | No changes needed (already correct) |

---

## Next Steps (Optional)

### Phase 2: Auto-Country-Detection
If users forget to set country code, implement:
```dart
// Detect country from device locale
import 'package:intl/intl.dart';

String getCountryCodeFromLocale() {
  final locale = Intl.defaultLocale ?? 'US';
  final countryMap = {
    'US': '+1',
    'GB': '+44',
    'PK': '+92',
    'IN': '+91',
    // ... more
  };
  return countryMap[locale.split('_').last] ?? '+1';
}
```

### Phase 3: Phone Number Input Widget
Create a reusable widget:
```dart
class PhoneNumberInput extends StatefulWidget {
  final String initialCountryCode;
  final Function(String phone, String countryCode) onChanged;
  // ...
}
```

---

## Success Indicators

After deployment, you should see:

- ✅ Country code selector on Emergency Contacts screen
- ✅ Selected contacts show country code (e.g., "Mom (+1)")
- ✅ SOS alert shows correct number of contacts (not 0)
- ✅ Cloud Function logs show formatted phone numbers
- ✅ Twilio receives SMS with correct E.164 format
- ✅ Emergency contacts receive SMS messages

---

## Support

If you encounter issues:

1. **Check Cloud Function Logs** - Most errors are logged there
2. **Verify Twilio Credentials** - Ensure TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN are correct
3. **Test with Different Number** - Try adding a number from a different country
4. **Review Twilio Account** - Check balance, number status, and recipient verification

---

**Estimated Time to Deploy:**
- Cloud Function: 2-5 minutes
- Flutter app rebuild: 5-10 minutes
- Testing: 5 minutes
- **Total: ~15-20 minutes**
