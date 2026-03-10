import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SosMessagingService {
  static final SosMessagingService _instance = SosMessagingService._internal();

  factory SosMessagingService() {
    return _instance;
  }

  SosMessagingService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cloud Function URL - update this with your actual function URL
  static const String _cloudFunctionUrl = 
    'https://us-central1-status-bands-2ad7b.cloudfunctions.net/sendSosAlert';

  /// Send SOS alert SMS to all emergency contacts
  /// 
  /// This function:
  /// 1. Gets current user location
  /// 2. Fetches emergency contacts from Firebase
  /// 3. Calls Cloud Function via HTTP to send SMS via Twilio
  /// 4. Returns results with success/failure details
  Future<Map<String, dynamic>> sendSosAlertToContacts({
    required String userName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current location
      print('📍 Fetching current location...');
      final position = await _getCurrentLocation();
      if (position == null) {
        throw Exception('Unable to get current location');
      }

      print('📍 Location: ${position.latitude}, ${position.longitude}');

      // Call Cloud Function via HTTP
      print('📱 Calling Cloud Function to send SMS...');
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': user.uid,
          'userName': userName,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ SOS alert sent successfully');
        return {
          'success': true,
          'message': result['message'] ?? 'SOS alert sent',
          'results': result['results'],
        };
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending SOS alert: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get current device location
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('⚠️ Location permission denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Fetch emergency contacts from Firestore
  Future<List<Map<String, String>>> _getEmergencyContacts(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('⚠️ User document not found');
        return [];
      }

      final data = userDoc.data();
      final contacts = data?['emergencyContacts'] as List<dynamic>?;

      if (contacts == null || contacts.isEmpty) {
        print('⚠️ No emergency contacts found');
        return [];
      }

      // Convert to List<Map<String, String>>
      return contacts
          .map((contact) => {
                'name': contact['name']?.toString() ?? 'Unknown',
                'phone': contact['phone']?.toString() ?? '',
              })
          .where((contact) => contact['phone']!.isNotEmpty)
          .toList();
    } catch (e) {
      print('❌ Error fetching emergency contacts: $e');
      return [];
    }
  }

  /// Test SMS sending (optional - for debugging)
  Future<Map<String, dynamic>> testSmsSending(String testPhoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final testUrl = _cloudFunctionUrl.replaceAll('sendSosAlert', 'testSosAlert');
      
      final response = await http.post(
        Uri.parse(testUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'testPhoneNumber': testPhoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ Test SMS sent successfully');
        return {
          'success': true,
          'message': result['message'] ?? 'Test SMS sent',
          'messageSid': result['messageSid'],
        };
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error testing SMS: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
