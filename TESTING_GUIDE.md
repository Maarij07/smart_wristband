# SOS SMS Testing Guide

## ✅ Deployment Complete

Your Firebase Cloud Functions are deployed and ready to test!

---

## Pre-Testing Checklist

- [ ] Flutter app updated with `flutter pub get`
- [ ] Permissions configured (Android & iOS)
- [ ] Emergency contact added in app
- [ ] User logged in
- [ ] Device has internet connection
- [ ] Device has location enabled

---

## Test 1: Test SMS Function (Optional)

This sends a test SMS to verify Twilio is working.

### Steps

1. Open Flutter app
2. Navigate to any screen
3. Run this code in a test or debug console:

```dart
import 'package:smart_wristband/services/sos_messaging_service.dart';

final sosService = SosMessagingService();
final result = await sosService.testSmsSending('+1234567890');
print(result);
```

### Expected Result

```
{
  "success": true,
  "message": "Test SMS sent successfully",
  "messageSid": "SM1234567890abcdef"
}
```

You should receive a test SMS on your phone:
```
🧪 Test SMS from Smart Wristband App - Twilio integration working!
```

---

## Test 2: Full SOS Flow (Main Test)

This tests the complete SOS alert system.

### Setup

1. **Add Emergency Contact**
   - Open app
   - Go to Emergency Contacts screen
   - Add a contact with your phone number
   - Save

2. **Ensure User is Logged In**
   - Verify you're logged in
   - Check user profile shows your name

3. **Enable Location**
   - Grant location permissions to app
   - Enable GPS on device

### Trigger SOS

**Option A: From Wristband**
- Press SOS button on wristband
- SOS Alert screen should appear

**Option B: Manually (For Testing)**
- Navigate to SOS Alert screen directly
- Screen should appear with alarm

### Expected Behavior

1. **SOS Alert Screen Appears**
   - Red screen with warning icon
   - Alarm plays
   - PIN entry fields visible

2. **SMS Sent Immediately** ✅
   - No need to enter PIN
   - SMS sent to emergency contact
   - Snackbar shows: "Emergency contacts notified"

3. **SMS Content**
   ```
   Your Contact {YourName} is in an emergency situation and has triggered SOS.
   
   📍 Live Location: https://maps.google.com/?q=40.7128,-74.0060
   ```

4. **Enter PIN to Stop Alarm**
   - Enter PIN: 1111
   - Alarm stops
   - Screen closes

### Verify Success

✅ **SMS Received** - Check your phone for SMS
✅ **Location Link Works** - Tap link to open Google Maps
✅ **Firestore Logged** - Check `sos_alerts` collection in Firebase Console

---

## Test 3: Multiple Emergency Contacts

Test with multiple emergency contacts.

### Setup

1. Add 3-5 emergency contacts
2. Use different phone numbers (or same for testing)

### Trigger SOS

1. Trigger SOS from wristband
2. SOS Alert screen appears

### Expected Result

✅ SMS sent to all contacts
✅ Snackbar shows: "SOS alert sent to 5 contacts"
✅ Firestore shows 5 documents in `sos_alerts`

---

## Test 4: Error Scenarios

### Scenario 1: No Emergency Contacts

**Setup:**
- Don't add any emergency contacts

**Trigger SOS:**
- Trigger SOS from wristband

**Expected Result:**
- Snackbar shows: "No emergency contacts configured"
- No SMS sent
- Firestore shows error

### Scenario 2: Location Disabled

**Setup:**
- Disable GPS on device
- Add emergency contact

**Trigger SOS:**
- Trigger SOS from wristband

**Expected Result:**
- SMS sent without location link
- Message shows: "Your Contact {Name} is in an emergency situation..."
- No maps link included

### Scenario 3: No Internet

**Setup:**
- Disable internet on device
- Add emergency contact

**Trigger SOS:**
- Trigger SOS from wristband

**Expected Result:**
- Snackbar shows error
- No SMS sent
- Check Cloud Function logs for error

---

## Monitoring During Tests

### Cloud Function Logs

```bash
firebase functions:log
```

Watch for:
- ✅ "📱 Sending SOS alert..."
- ✅ "✅ SMS sent to..."
- ❌ "❌ Failed to send SMS..."

### Firestore Audit Trail

1. Go to Firebase Console
2. Firestore Database
3. Collection: `sos_alerts`
4. View documents created

Each document should show:
- userId
- userName
- recipientName
- recipientPhone
- latitude
- longitude
- messageSid
- timestamp
- status (sent/failed)

### Twilio Console

1. Go to https://www.twilio.com/console
2. Logs → SMS
3. View sent messages

---

## Test Results Template

Use this to document your tests:

```
Test Date: _______________
Tester: _______________

Test 1: Test SMS Function
- [ ] Test SMS sent successfully
- [ ] Received test SMS on phone
- [ ] Result: PASS / FAIL

Test 2: Full SOS Flow
- [ ] SOS screen appeared
- [ ] SMS sent immediately
- [ ] Snackbar showed success
- [ ] SMS received on phone
- [ ] Location link works
- [ ] Firestore logged event
- [ ] Result: PASS / FAIL

Test 3: Multiple Contacts
- [ ] Added 3+ emergency contacts
- [ ] SOS triggered
- [ ] SMS sent to all contacts
- [ ] Firestore shows all events
- [ ] Result: PASS / FAIL

Test 4: Error Scenarios
- [ ] No contacts error handled
- [ ] Location disabled handled
- [ ] No internet handled
- [ ] Result: PASS / FAIL

Overall Result: PASS / FAIL

Notes:
_________________________________
_________________________________
```

---

## Common Issues & Solutions

### Issue: SMS Not Received

**Check:**
1. Cloud Function logs: `firebase functions:log`
2. Firestore `sos_alerts` collection for errors
3. Twilio console for delivery status
4. Phone number format (should be +1234567890)

**Solution:**
- Verify Twilio credentials are correct
- Check phone number is valid
- Ensure emergency contact is saved
- Check internet connection

### Issue: Location Not Included

**Check:**
1. Device GPS enabled
2. Location permissions granted
3. Cloud Function logs

**Solution:**
- Enable GPS on device
- Grant location permissions
- Restart app
- Try again

### Issue: Firestore Not Logging

**Check:**
1. User is authenticated
2. Firestore has write permissions
3. Cloud Function logs

**Solution:**
- Ensure user is logged in
- Check Firestore security rules
- Verify Cloud Function has access

### Issue: Alarm Not Playing

**Check:**
1. Device volume is on
2. Audio file exists: `assets/sounds/emergency_alarm.mp3`
3. Device is not in silent mode

**Solution:**
- Increase device volume
- Check audio file exists
- Disable silent mode

---

## Performance Metrics

Track these during testing:

| Metric | Expected | Actual |
|--------|----------|--------|
| Time to send SMS | <10 seconds | _____ |
| SMS delivery time | 1-5 seconds | _____ |
| Firestore logging | <1 second | _____ |
| Location fetch | 2-5 seconds | _____ |

---

## Next Steps After Testing

### If All Tests Pass ✅

1. Document results
2. Deploy to production
3. Train users on emergency contacts setup
4. Monitor logs regularly

### If Tests Fail ❌

1. Check Cloud Function logs
2. Verify Twilio credentials
3. Check Firestore permissions
4. Review error messages
5. Contact support if needed

---

## Support

### View Logs

```bash
firebase functions:log
```

### Check Firestore

Firebase Console → Firestore → `sos_alerts` collection

### Check Twilio

https://www.twilio.com/console → SMS Logs

### Debug Mode

Add this to `sos_messaging_service.dart` for more logging:

```dart
print('📍 Location: ${position.latitude}, ${position.longitude}');
print('📞 Contacts: ${emergencyContacts.length}');
print('📱 Calling Cloud Function...');
```

---

## Ready to Test?

You're all set! Follow the tests above and let me know the results.

