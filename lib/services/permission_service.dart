import 'package:permission_handler/permission_handler.dart' as permission_handler;

class PermissionService {
  // Check if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    final locationStatus = await permission_handler.Permission.location.status;
    final notificationStatus = await permission_handler.Permission.notification.status;
    
    // Check Bluetooth permissions (both new and legacy)
    final bluetoothStatus = await permission_handler.Permission.bluetooth.status;
    final bluetoothConnectStatus = await permission_handler.Permission.bluetoothConnect.status;
    final bluetoothScanStatus = await permission_handler.Permission.bluetoothScan.status;
    
    final bluetoothGranted = bluetoothConnectStatus.isGranted && bluetoothScanStatus.isGranted || bluetoothStatus.isGranted;
    
    final contactsStatus = await permission_handler.Permission.contacts.status;

    return locationStatus.isGranted &&
           notificationStatus.isGranted &&
           bluetoothGranted &&
           contactsStatus.isGranted;
  }
  
  // Check individual permissions
  static Future<bool> isLocationPermissionGranted() async {
    return await permission_handler.Permission.location.status.isGranted;
  }
  
  static Future<bool> isNotificationPermissionGranted() async {
    return await permission_handler.Permission.notification.status.isGranted;
  }
  
  static Future<bool> isContactsPermissionGranted() async {
    return await permission_handler.Permission.contacts.status.isGranted;
  }

  static Future<bool> isBluetoothPermissionGranted() async {
    // Check for both legacy and new Bluetooth permissions
    final bluetoothStatus = await permission_handler.Permission.bluetooth.status;
    final bluetoothConnectStatus = await permission_handler.Permission.bluetoothConnect.status;
    final bluetoothScanStatus = await permission_handler.Permission.bluetoothScan.status;
    
    // On newer Android versions, we need both connect and scan permissions
    if (bluetoothConnectStatus.isGranted && bluetoothScanStatus.isGranted) {
      return true;
    }
    
    // On older versions, just check the basic bluetooth permission
    return bluetoothStatus.isGranted;
  }
  
  // Request all required permissions
  static Future<Map<String, bool>> requestAllPermissions() async {
    Map<String, bool> results = {};
    
    // Request location permission
    final locationResult = await permission_handler.Permission.location.request();
    results['location'] = locationResult.isGranted;
    
    // Request notification permission
    final notificationResult = await permission_handler.Permission.notification.request();
    results['notification'] = notificationResult.isGranted;
    
    // Request audio permission (needed for SOS alarm to override silent mode)
    final audioResult = await permission_handler.Permission.audio.request();
    results['audio'] = audioResult.isGranted;
    
    // Request contacts permission (needed for emergency contacts)
    final contactsResult = await permission_handler.Permission.contacts.request();
    results['contacts'] = contactsResult.isGranted;

    // Request bluetooth permission (needed for wristband connection)
    try {
      // Try new Bluetooth permissions first
      final bluetoothConnectResult = await permission_handler.Permission.bluetoothConnect.request();
      final bluetoothScanResult = await permission_handler.Permission.bluetoothScan.request();
      
      if (bluetoothConnectResult.isGranted && bluetoothScanResult.isGranted) {
        results['bluetooth'] = true;
      } else {
        // Fall back to legacy permission
        final bluetoothResult = await permission_handler.Permission.bluetooth.request();
        results['bluetooth'] = bluetoothResult.isGranted;
      }
    } catch (e) {
      // If new permissions fail, try legacy
      final bluetoothResult = await permission_handler.Permission.bluetooth.request();
      results['bluetooth'] = bluetoothResult.isGranted;
    }
    
    return results;
  }
  
  // Request individual permissions
  static Future<bool> requestLocationPermission() async {
    final status = await permission_handler.Permission.location.request();
    return status.isGranted;
  }
  
  static Future<bool> requestNotificationPermission() async {
    final status = await permission_handler.Permission.notification.request();
    return status.isGranted;
  }
  
  static Future<bool> requestAudioPermission() async {
    final status = await permission_handler.Permission.audio.request();
    return status.isGranted;
  }
  
  static Future<bool> requestContactsPermission() async {
    final status = await permission_handler.Permission.contacts.request();
    return status.isGranted;
  }

  static Future<bool> requestBluetoothPermission() async {
    try {
      // Try to request both new and legacy Bluetooth permissions
      final bluetoothConnectStatus = await permission_handler.Permission.bluetoothConnect.request();
      final bluetoothScanStatus = await permission_handler.Permission.bluetoothScan.request();
      
      // If both new permissions are granted, return true
      if (bluetoothConnectStatus.isGranted && bluetoothScanStatus.isGranted) {
        return true;
      }
      
      // Fall back to legacy Bluetooth permission
      final bluetoothStatus = await permission_handler.Permission.bluetooth.request();
      return bluetoothStatus.isGranted;
    } catch (e) {
      // If there's an error, try the legacy permission
      try {
        final bluetoothStatus = await permission_handler.Permission.bluetooth.request();
        return bluetoothStatus.isGranted;
      } catch (e2) {
        return false;
      }
    }
  }
  

  
  // Open app settings if permissions are denied
  static Future<void> openAppSettingsDialog() async {
    await permission_handler.openAppSettings();
  }
}
