import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'dart:convert';

class User {
  final String id;
  final String email;
  final String name;
  final String? age;
  final String? phoneNumber;
  final String? profilePicture;
  final String? bio;
  final String? relationshipStatus;
  final Map<String, String>? socialMediaLinks;
  final Map<String, String>? privacySettings;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.phoneNumber,
    this.profilePicture,
    this.bio,
    this.relationshipStatus,
    this.socialMediaLinks,
    this.privacySettings,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    print('🔍 Loading user from Firestore:');
    print('   - profilePicture field: ${data['profilePicture']}');
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      age: data['age']?.toString(),
      phoneNumber: data['phoneNumber'],
      profilePicture: data['profilePicture'] ?? data['photoUrl'],
      bio: data['bio'],
      relationshipStatus: data['relationshipStatus'],
      socialMediaLinks: _parseStringMap(data['socialMediaLinks']),
      privacySettings: _parseStringMap(data['privacySettings']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, String>? _parseStringMap(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(
          key.toString(),
          value?.toString() ?? '',
        ),
      );
    }
    return null;
  }
}

class Device {
  final String id;
  final String name;
  final String? platformName;
  final String? deviceType;
  final DateTime connectedAt;
  final bool isConnected;
  final String? batteryLevel;

  Device({
    required this.id,
    required this.name,
    this.platformName,
    this.deviceType,
    required this.connectedAt,
    this.isConnected = false,
    this.batteryLevel,
  });

  factory Device.fromMap(Map<String, dynamic> data) {
    return Device(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown Device',
      platformName: data['platformName'],
      deviceType: data['deviceType'],
      connectedAt: (data['connectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isConnected: data['isConnected'] ?? false,
      batteryLevel: data['batteryLevel'],
    );
  }
}

class UserContext extends ChangeNotifier {
  static const String _profilePictureCacheKeyPrefix = 'cached_profile_picture_url_';

  User? _user;
  Device? _connectedDevice;
  bool _isLoading = false;
  bool _isSosScreenShowing = false;

  User? get user => _user;
  Device? get connectedDevice => _connectedDevice;
  bool get isLoading => _isLoading;
  bool get isSosScreenShowing => _isSosScreenShowing;
  void setIsSosScreenShowing(bool showing) {
    _isSosScreenShowing = showing;
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void setConnectedDevice(Device? device) {
    _connectedDevice = device;
    notifyListeners();
  }

  void updateDeviceConnectionStatus(bool isConnected) {
    if (_connectedDevice != null) {
      _connectedDevice = Device(
        id: _connectedDevice!.id,
        name: _connectedDevice!.name,
        platformName: _connectedDevice!.platformName,
        deviceType: _connectedDevice!.deviceType,
        connectedAt: _connectedDevice!.connectedAt,
        isConnected: isConnected,
        batteryLevel: _connectedDevice!.batteryLevel,
      );
      notifyListeners();
    }
  }
  
  void updateDeviceBatteryLevel(String batteryLevel) {
    if (_connectedDevice != null) {
      _connectedDevice = Device(
        id: _connectedDevice!.id,
        name: _connectedDevice!.name,
        platformName: _connectedDevice!.platformName,
        deviceType: _connectedDevice!.deviceType,
        connectedAt: _connectedDevice!.connectedAt,
        isConnected: _connectedDevice!.isConnected,
        batteryLevel: batteryLevel,
      );
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _connectedDevice = null;
    notifyListeners();
  }
  
  // Load user data from Firebase
  Future<void> loadUserData(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && _user != null && _user!.id == uid) {
      return;
    }

    print('Starting to load user data for UID: $uid');
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      print('Firebase document exists: ${doc.exists}');
      if (doc.exists) {
        final user = User.fromFirestore(doc);
        print('User data from Firestore: name=${user.name}, email=${user.email}');
        _user = user;
        await _cacheProfilePicture(uid, _user!.profilePicture);
        notifyListeners();
        print('User data loaded successfully: ${user.name}, ${user.email}');
      } else {
        print('User document not found for UID: $uid');
        // Create a default user if not found
        final cachedProfilePicture = await _getCachedProfilePicture(uid);
        _user = User(
          id: uid,
          email: 'user2@example.com',
          name: 'User',
          profilePicture: cachedProfilePicture,
          createdAt: DateTime.now(),
        );
        notifyListeners();
        print('Created default user');
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Create a default user on error
      final cachedProfilePicture = await _getCachedProfilePicture(uid);
      _user = User(
        id: uid,
        email: 'user2@example.com',
        name: 'User',
        profilePicture: cachedProfilePicture,
        createdAt: DateTime.now(),
      );
      notifyListeners();
      print('Created default user due to error');
    }
  }

  Future<void> loadCachedProfilePicture(String uid) async {
    final cachedProfilePicture = await _getCachedProfilePicture(uid);
    if (cachedProfilePicture == null) {
      return;
    }

    if (_user == null) {
      return;
    }

    if (_user!.profilePicture == cachedProfilePicture) {
      return;
    }

    _user = User(
      id: _user!.id,
      email: _user!.email,
      name: _user!.name,
      phoneNumber: _user!.phoneNumber,
      profilePicture: cachedProfilePicture,
      bio: _user!.bio,
      relationshipStatus: _user!.relationshipStatus,
      socialMediaLinks: _user!.socialMediaLinks,
      privacySettings: _user!.privacySettings,
      createdAt: _user!.createdAt,
      lastLoginAt: _user!.lastLoginAt,
    );
    notifyListeners();
  }

  Future<String?> _getCachedProfilePicture(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_profilePictureCacheKeyPrefix$uid');
  }

  Future<void> _cacheProfilePicture(String uid, String? url) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_profilePictureCacheKeyPrefix$uid';

    if (url == null || url.isEmpty) {
      await prefs.remove(key);
      return;
    }

    await prefs.setString(key, url);
  }

  // Get user health metrics from context or device
  Map<String, dynamic>? getUserHealthMetrics() {
    // This would typically fetch from the connected device or Firestore
    if (_connectedDevice != null) {
      // Return actual device metrics when connected
      return {
        'heartRate': 72,
        'steps': 8432,
        'calories': 420,
        'distance': 6.5,
        'sleepHours': 7.5,
        'stressLevel': 3,
        'bloodPressure': {'systolic': 120, 'diastolic': 80},
        'connections': 12,
        'onlineNow': 7,
        'battery': _connectedDevice!.batteryLevel ?? 'N/A',
        'signal': _connectedDevice!.isConnected ? 'Strong' : 'Weak',
        'recentActivities': [
          {'title': 'SOS Alert Sent', 'time': '10:15 PM', 'icon': 'warning', 'color': 'red'},
          {'title': 'New Connection', 'time': 'Yesterday', 'icon': 'person_add', 'color': 'green'},
          {'title': 'Wristband Paired', 'time': '2 days ago', 'icon': 'bluetooth_connected', 'color': 'blue'},
        ],
      };
    }
    return {
      'heartRate': 0,
      'steps': 0,
      'calories': 0,
      'distance': 0.0,
      'sleepHours': 0.0,
      'stressLevel': 0,
      'bloodPressure': {'systolic': 0, 'diastolic': 0},
      'connections': 0,
      'onlineNow': 0,
      'battery': 'N/A',
      'signal': 'N/A',
      'recentActivities': [],
    };
  }



  // Get SOS PIN from user context
  String? getSosPin() {
    // This would typically be stored securely
    return null; // Placeholder - would come from secure storage
  }

  // Update user profile in both context and Firebase
  Future<void> updateUserProfile({
    String? age,
    String? phoneNumber,
    String? bio,
    String? profilePicture,
    String? relationshipStatus,
    Map<String, String>? socialMediaLinks,
    Map<String, String>? privacySettings,
  }) async {
    if (_user != null) {
      // Update the user object in context
      _user = User(
        id: _user!.id,
        email: _user!.email,
        name: _user!.name,
        age: age ?? _user!.age,
        phoneNumber: phoneNumber ?? _user!.phoneNumber,
        profilePicture: profilePicture ?? _user!.profilePicture,
        bio: bio ?? _user!.bio,
        relationshipStatus: relationshipStatus ?? _user!.relationshipStatus,
        socialMediaLinks: socialMediaLinks ?? _user!.socialMediaLinks,
        privacySettings: privacySettings ?? _user!.privacySettings,
        createdAt: _user!.createdAt,
        lastLoginAt: _user!.lastLoginAt,
      );
      
      if (profilePicture != null) {
        await _cacheProfilePicture(_user!.id, _user!.profilePicture);
      }

      notifyListeners();
      
      // Update in Firebase
      await FirebaseService.updateUserProfile(
        uid: _user!.id,
        age: age,
        phoneNumber: phoneNumber,
        bio: bio,
        profilePicture: profilePicture,
        relationshipStatus: relationshipStatus,
        socialMediaLinks: socialMediaLinks,
        privacySettings: privacySettings,
      );

      // If relationship status changed, send appropriate command to wristband
      if (relationshipStatus != null && _connectedDevice != null) {
        await _sendRelationshipStatusCommand(relationshipStatus);
      }
    }
  }

  // Send appropriate command to wristband based on relationship status
  Future<void> _sendRelationshipStatusCommand(String status) async {
    print('Sending relationship status command for: $status');
    switch (status) {
      case 'Single':
        await setWristbandToSingle();
        break;
      case 'Taken':
        await setWristbandToTaken();
        break;
      case 'Complicated':
        await setWristbandToComplicated();
        break;
      case 'Private':
        await setWristbandToPrivate();
        break;
      default:
        await setWristbandToPrivate(); // Default to private
        break;
    }
  }

  // Method to send command to wristband
  Future<void> sendCommandToWristband(String command) async {
    print('Attempting to send command: $command');
    if (_connectedDevice != null) {
      print('Connected device found: ${_connectedDevice!.id}');
      try {
        // Get the connected device from FlutterBluePlus
        BluetoothDevice device = BluetoothDevice.fromId(_connectedDevice!.id);
        
        // Find the service and characteristic for communication
        // YOUR WRISTBAND'S ACTUAL SERVICE UUID
        const String wristbandServiceUuid = '12345678-04d2-162e-04d2-56789abcdef0';
        const String wristbandWriteCharUuid = '12345678-04d2-162e-04d2-56789abcdef1';
        
        // Discover services
        List<BluetoothService> services = await device.discoverServices();
        
        BluetoothService? wristbandService;
        try {
          wristbandService = services.firstWhere(
            (service) => service.uuid.toString().toLowerCase() == wristbandServiceUuid,
          );
          print('✓ Found wristband service in UserContext');
        } catch (e) {
          print('❌ Could not find wristband service in UserContext');
          return;
        }
        
        // Find the characteristic for writing commands
        BluetoothCharacteristic? commandCharacteristic;
        try {
          commandCharacteristic = wristbandService.characteristics.firstWhere(
            (char) => char.uuid.toString().toLowerCase() == wristbandWriteCharUuid,
          );
          print('✓ Found write characteristic in UserContext');
        } catch (e) {
          print('❌ Could not find write characteristic in UserContext');
          return;
        }
        
        // Convert the command string to bytes and send
        List<int> commandBytes = utf8.encode(command);
        // Check if the characteristic supports write or writeWithoutResponse
        if (commandCharacteristic.properties.writeWithoutResponse) {
          await commandCharacteristic.write(commandBytes, withoutResponse: true);
          print('Sent BLE command (without response): $command');
        } else if (commandCharacteristic.properties.write) {
          await commandCharacteristic.write(commandBytes, withoutResponse: false);
          print('Sent BLE command (with response): $command');
        } else {
          print('Characteristic does not support write operations');
        }
        
        print('Command "$command" sent to wristband successfully');
      } catch (e) {
        print('Error sending command to wristband: $e');
        // Handle error appropriately
      }
    } else {
      print('No wristband connected');
    }
  }

  // Specific command methods for different statuses
  Future<void> setWristbandToSingle() async {
    await sendCommandToWristband('S'); // Set Single - Green light
  }

  Future<void> setWristbandToTaken() async {
    await sendCommandToWristband('T'); // Set Taken - Red light
  }

  Future<void> setWristbandToComplicated() async {
    await sendCommandToWristband('C'); // Set Complicated - Yellow light
  }

  Future<void> setWristbandToPrivate() async {
    await sendCommandToWristband('P'); // Set Private - Light off
  }

  Future<void> triggerWristbandFlash() async {
    await sendCommandToWristband('F'); // Flash notification
  }

  Future<void> triggerWristbandHaptic() async {
    await sendCommandToWristband('H'); // Haptic vibration
  }

  Future<void> triggerWristbandAudio() async {
    await sendCommandToWristband('A'); // Audio notification
  }

  Future<void> startWristbandFindMe() async {
    await sendCommandToWristband('?'); // Find Me alarm
  }

  Future<void> stopWristbandFindMe() async {
    await sendCommandToWristband('!'); // Stop Find Me
  }

  Future<void> confirmWristbandSos() async {
    print('Sending SOS confirmation signal (K) to wristband');
    await sendCommandToWristband('K'); // SOS OK confirmation
    print('SOS confirmation signal sent successfully');
  }

  Future<void> queryWristbandStatus() async {
    await sendCommandToWristband('Q'); // Query status
  }
}