import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class User {
  final String id;
  final String email;
  final String name;
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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      profilePicture: data['profilePicture'],
      bio: data['bio'],
      relationshipStatus: data['relationshipStatus'],
      socialMediaLinks: data['socialMediaLinks'] is Map<String, dynamic> 
          ? data['socialMediaLinks'].map((key, value) => MapEntry(key, value.toString()))
          : null,
      privacySettings: data['privacySettings'] is Map<String, dynamic> 
          ? data['privacySettings'].map((key, value) => MapEntry(key, value.toString()))
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
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
  User? _user;
  Device? _connectedDevice;
  bool _isLoading = false;

  User? get user => _user;
  Device? get connectedDevice => _connectedDevice;
  bool get isLoading => _isLoading;

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

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _connectedDevice = null;
    notifyListeners();
  }

  // Get user health metrics from context or device
  Map<String, dynamic>? getUserHealthMetrics() {
    // This would typically fetch from the connected device or Firestore
    if (_connectedDevice != null) {
      // Placeholder for actual device metrics
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
        'battery': '87%',
        'signal': 'Strong',
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
      'battery': 'Unknown',
      'signal': 'Unknown',
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
    String? phoneNumber,
    String? bio,
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
        phoneNumber: phoneNumber ?? _user!.phoneNumber,
        profilePicture: _user!.profilePicture,
        bio: bio ?? _user!.bio,
        relationshipStatus: relationshipStatus ?? _user!.relationshipStatus,
        socialMediaLinks: socialMediaLinks ?? _user!.socialMediaLinks,
        privacySettings: privacySettings ?? _user!.privacySettings,
        createdAt: _user!.createdAt,
        lastLoginAt: _user!.lastLoginAt,
      );
      
      notifyListeners();
      
      // Update in Firebase
      await FirebaseService.updateUserProfile(
        uid: _user!.id,
        phoneNumber: phoneNumber,
        bio: bio,
        relationshipStatus: relationshipStatus,
        socialMediaLinks: socialMediaLinks,
        privacySettings: privacySettings,
      );
    }
  }
}