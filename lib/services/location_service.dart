import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Location _location = Location();
  LocationData? _lastKnownLocation;
  bool _isLocationInitialized = false;

  // Keys for shared preferences
  static const String _latKey = 'last_known_lat';
  static const String _lngKey = 'last_known_lng';
  static const String _timestampKey = 'location_timestamp';

  Future<void> initialize() async {
    if (_isLocationInitialized) return;
    
    // Load cached location first
    await _loadCachedLocation();
    
    // Check permissions and get fresh location
    await _checkAndRequestPermissions();
    
    _isLocationInitialized = true;
  }

  Future<void> _loadCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Use cached location if it's less than 5 minutes old
      if (now - timestamp < 5 * 60 * 1000) {
        final lat = prefs.getDouble(_latKey);
        final lng = prefs.getDouble(_lngKey);
        
        if (lat != null && lng != null) {
          _lastKnownLocation = LocationData.fromMap({
            'latitude': lat,
            'longitude': lng,
            'accuracy': 0.0,
            'altitude': 0.0,
            'speed': 0.0,
            'speedAccuracy': 0.0,
            'heading': 0.0,
            'time': timestamp.toDouble(),
          });
        }
      }
    } catch (e) {
      print('Error loading cached location: $e');
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      // Get current location
      final locationData = await _location.getLocation();
      await _updateLastKnownLocation(locationData);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _updateLastKnownLocation(LocationData locationData) async {
    _lastKnownLocation = locationData;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, locationData.latitude!);
      await prefs.setDouble(_lngKey, locationData.longitude!);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching location: $e');
    }
  }

  Future<LocationData?> getCurrentLocation() async {
    if (_lastKnownLocation != null) {
      return _lastKnownLocation;
    }

    await initialize();
    return _lastKnownLocation;
  }

  Future<LocationData?> getFreshLocation() async {
    try {
      final locationData = await _location.getLocation();
      await _updateLastKnownLocation(locationData);
      return locationData;
    } catch (e) {
      print('Error getting fresh location: $e');
      return _lastKnownLocation;
    }
  }

  bool get hasLocation => _lastKnownLocation != null;
  
  LocationData? get lastKnownLocation => _lastKnownLocation;
}