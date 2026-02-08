import 'package:firebase_database/firebase_database.dart';

class RealtimeUserLocation {
  final String userId;
  final String name;
  final String? profilePicture;
  final double latitude;
  final double longitude;
  final DateTime? lastUpdatedAt;
  final String? age;

  RealtimeUserLocation({
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.profilePicture,
    this.lastUpdatedAt,
    this.age,
  });

  factory RealtimeUserLocation.fromMap(String userId, Map<dynamic, dynamic> data) {
    final lat = data['lat'] as num?;
    final lng = data['lng'] as num?;
    final updatedAt = data['updatedAt'] as num?;

    return RealtimeUserLocation(
      userId: userId,
      name: data['name']?.toString() ?? 'User',
      profilePicture: data['profilePicture']?.toString(),
      age: data['age']?.toString(),
      latitude: lat?.toDouble() ?? 0.0,
      longitude: lng?.toDouble() ?? 0.0,
      lastUpdatedAt: updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAt.toInt())
          : null,
    );
  }
}

class RealtimeLocationService {
  static const int defaultGeohashLength = 6;
  static const double neighborOffsetDegrees = 0.01;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  String? _currentUserPrefix;

  DatabaseReference _locationRef(String prefix) {
    return _database.ref('locations/$prefix');
  }

  Stream<DatabaseEvent> listenToPrefix(String prefix) {
    return _locationRef(prefix).onValue;
  }

  Set<String> getNearbyPrefixes(double latitude, double longitude,
      {int length = defaultGeohashLength, double offsetDegrees = neighborOffsetDegrees}) {
    final prefixes = <String>{};
    final offsets = [-offsetDegrees, 0.0, offsetDegrees];

    for (final latOffset in offsets) {
      for (final lngOffset in offsets) {
        final lat = _clampLatitude(latitude + latOffset);
        final lng = _wrapLongitude(longitude + lngOffset);
        final geohash = encodeGeohash(lat, lng, length: length);
        prefixes.add(geohash);
      }
    }

    return prefixes;
  }

  Future<void> updateCurrentUserLocation({
    required String userId,
    required String name,
    required double latitude,
    required double longitude,
    String? profilePicture,
    String? age,
    int geohashLength = defaultGeohashLength,
  }) async {
    final prefix = encodeGeohash(latitude, longitude, length: geohashLength);

    if (_currentUserPrefix != null && _currentUserPrefix != prefix) {
      await _locationRef(_currentUserPrefix!).child(userId).remove();
    }

    _currentUserPrefix = prefix;

    await _locationRef(prefix).child(userId).set({
      'lat': latitude,
      'lng': longitude,
      'name': name,
      'profilePicture': profilePicture,
      'age': age,
      'updatedAt': ServerValue.timestamp,
    });
  }

  String encodeGeohash(double latitude, double longitude,
      {int length = defaultGeohashLength}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    var latMin = -90.0;
    var latMax = 90.0;
    var lonMin = -180.0;
    var lonMax = 180.0;

    var hash = StringBuffer();
    var bits = 0;
    var bitsTotal = 0;
    var hashValue = 0;
    var even = true;

    while (hash.length < length) {
      if (even) {
        final lonMid = (lonMin + lonMax) / 2;
        if (longitude >= lonMid) {
          hashValue = (hashValue << 1) + 1;
          lonMin = lonMid;
        } else {
          hashValue = (hashValue << 1);
          lonMax = lonMid;
        }
      } else {
        final latMid = (latMin + latMax) / 2;
        if (latitude >= latMid) {
          hashValue = (hashValue << 1) + 1;
          latMin = latMid;
        } else {
          hashValue = (hashValue << 1);
          latMax = latMid;
        }
      }

      even = !even;
      bits++;
      bitsTotal++;

      if (bits == 5) {
        hash.write(base32[hashValue]);
        bits = 0;
        hashValue = 0;
      }
    }

    return hash.toString();
  }

  double _clampLatitude(double latitude) {
    if (latitude > 90.0) return 90.0;
    if (latitude < -90.0) return -90.0;
    return latitude;
  }

  double _wrapLongitude(double longitude) {
    if (longitude > 180.0) return longitude - 360.0;
    if (longitude < -180.0) return longitude + 360.0;
    return longitude;
  }
}
