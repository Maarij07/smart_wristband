import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Check if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    final locationStatus = await Permission.location.status;
    final notificationStatus = await Permission.notification.status;
    
    return locationStatus.isGranted && 
           notificationStatus.isGranted;
  }
  
  // Check individual permissions
  static Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.status.isGranted;
  }
  
  static Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.status.isGranted;
  }
  
  // Request all required permissions
  static Future<Map<String, bool>> requestAllPermissions() async {
    Map<String, bool> results = {};
    
    // Request location permission
    final locationResult = await Permission.location.request();
    results['location'] = locationResult.isGranted;
    
    // Request notification permission
    final notificationResult = await Permission.notification.request();
    results['notification'] = notificationResult.isGranted;
    
    // Request audio permission (needed for SOS alarm to override silent mode)
    final audioResult = await Permission.audio.request();
    results['audio'] = audioResult.isGranted;
    
    return results;
  }
  
  // Request individual permissions
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  
  static Future<bool> requestAudioPermission() async {
    final status = await Permission.audio.request();
    return status.isGranted;
  }
  

  
  // Open app settings if permissions are denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}