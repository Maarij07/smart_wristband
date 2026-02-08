import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:convert';
import '../utils/colors.dart';
import '../services/user_context.dart';
import '../services/location_service.dart';
import '../services/realtime_location_service.dart';
import '../services/nudges_service.dart';

class MapsTab extends StatefulWidget {
  final MapController mapController;
  final LocationService locationService;
  final bool isMapInitialized;
  final LocationData? currentLocation;

  const MapsTab({
    super.key,
    required this.mapController,
    required this.locationService,
    required this.isMapInitialized,
    required this.currentLocation,
  });

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  RealtimeUserLocation? _selectedUser;
  BluetoothCharacteristic? _outgoingDataCharacteristic;
  final RealtimeLocationService _realtimeLocationService =
      RealtimeLocationService();
  final NudgesService _nudgesService = NudgesService();
  final Location _liveLocationService = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  DateTime? _lastLocationUpdateAt;
  final Map<String, StreamSubscription<DatabaseEvent>>
      _prefixSubscriptions = {};
  final Map<String, Set<String>> _prefixUserIds = {};
  final Map<String, RealtimeUserLocation> _nearbyUsersById = {};
  LocationData? _liveLocation;
  bool _rtdbPermissionDenied = false;
  
  // Method to send nudge signal to wristband
  Future<void> _sendNudgeSignal() async {
    try {
      print('H Nudge signal triggered');
      await _sendBleCommand('H'); // 'H' command for nudge
      
      if (mounted) {
        print('Nudge signal sent to wristband');
      }
    } catch (e) {
      print('Error sending nudge signal: $e');
    }
  }

  Future<void> _handleSendNudge(RealtimeUserLocation userLocation) async {
    final user = context.read<UserContext>().user;
    if (user == null || user.id.isEmpty) {
      return;
    }

    try {
      await _nudgesService.sendNudge(
        receiverId: userLocation.userId,
        receiverName: userLocation.name,
        receiverProfilePicture: userLocation.profilePicture,
        senderName: user.name,
        senderProfilePicture: user.profilePicture,
      );
    } catch (e) {
      print('Error sending nudge to Firestore: $e');
    }
  }
  
  // Method to send BLE command to wristband
  Future<void> _sendBleCommand(String command) async {
    try {
      // Send command to wristband
      if (_outgoingDataCharacteristic != null) {
        List<int> commandBytes = utf8.encode(command);
        
        // Check which write method to use
        if (_outgoingDataCharacteristic!.properties.writeWithoutResponse) {
          await _outgoingDataCharacteristic!.write(commandBytes, withoutResponse: true);
          print('Sent BLE command (without response): $command');
        } else if (_outgoingDataCharacteristic!.properties.write) {
          await _outgoingDataCharacteristic!.write(commandBytes, withoutResponse: false);
          print('Sent BLE command (with response): $command');
        }
      } else {
        // Try to find the outgoing characteristic
        final userContext = Provider.of<UserContext>(context, listen: false);
        if (userContext.connectedDevice != null) {
          await _findAndSendCommand(userContext.connectedDevice!.id, command);
        }
      }
    } catch (e) {
      print('Error sending BLE command: $e');
    }
  }
  
  // Method to find and send command to device
  Future<void> _findAndSendCommand(String deviceId, String command) async {
    try {
      BluetoothDevice device = BluetoothDevice.fromId(deviceId);
      List<BluetoothService> services = await device.discoverServices();
      
      print('Found ${services.length} services');
      
      // YOUR WRISTBAND'S ACTUAL SERVICE UUID
      const String wristbandServiceUuid = '12345678-04d2-162e-04d2-56789abcdef0';
      const String wristbandWriteCharUuid = '12345678-04d2-162e-04d2-56789abcdef1';
      
      // Find your wristband's service
      BluetoothService? wristbandService;
      try {
        wristbandService = services.firstWhere(
          (service) => service.uuid.toString().toLowerCase() == wristbandServiceUuid,
        );
        print('✓ Found wristband service: ${wristbandService.uuid}');
      } catch (e) {
        print('❌ Could not find wristband service with UUID: $wristbandServiceUuid');
        // Print all available services for debugging
        print('Available services:');
        for (var service in services) {
          print('  - ${service.uuid}');
        }
        return;
      }
      
      // Find the write characteristic
      BluetoothCharacteristic? outgoingChar;
      try {
        outgoingChar = wristbandService.characteristics.firstWhere(
          (char) => char.uuid.toString().toLowerCase() == wristbandWriteCharUuid,
        );
        print('✓ Found write characteristic: ${outgoingChar.uuid}');
        print('  Properties: writeWithoutResponse=${outgoingChar.properties.writeWithoutResponse}');
      } catch (e) {
        print('❌ Could not find write characteristic with UUID: $wristbandWriteCharUuid');
        // Print all available characteristics for debugging
        print('Available characteristics in service:');
        for (var char in wristbandService.characteristics) {
          print('  - ${char.uuid} (write: ${char.properties.write}, writeWithoutResponse: ${char.properties.writeWithoutResponse})');
        }
        return;
      }
      
      // Send the command
      if (outgoingChar != null) {
        List<int> commandBytes = utf8.encode(command);
        print('Sending command: $command (bytes: $commandBytes)');
        
        try {
          // Your wristband uses writeWithoutResponse
          await outgoingChar.write(commandBytes, withoutResponse: true);
          print('✓ Successfully sent BLE command: $command');
          
          // Save reference for future use
          _outgoingDataCharacteristic = outgoingChar;
        } catch (e) {
          print('❌ Error writing to characteristic: $e');
        }
      }
    } catch (e) {
      print('❌ Error finding and sending command: $e');
    }
  }
  
  Widget _buildMapSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        children: [
          // Header skeleton
          Container(
            height: 40,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
          // Map area skeleton
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Loading map...',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startRealtimeLocationUpdates();
    if (widget.currentLocation?.latitude != null &&
        widget.currentLocation?.longitude != null) {
      _updateNearbySubscriptions(
        widget.currentLocation!.latitude!,
        widget.currentLocation!.longitude!,
      );
    }
  }

  @override
  void dispose() {
    for (final subscription in _prefixSubscriptions.values) {
      subscription.cancel();
    }
    _prefixSubscriptions.clear();
    _prefixUserIds.clear();
    _nearbyUsersById.clear();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRealtimeLocationUpdates() async {
    try {
      await _liveLocationService.changeSettings(
        interval: 10000,
        distanceFilter: 5,
      );
    } catch (e) {
      // Ignore errors from settings on older platforms.
    }

    _locationSubscription =
        _liveLocationService.onLocationChanged.listen((locationData) async {
      _liveLocation = locationData;
      if (!mounted) {
        return;
      }

      if (_rtdbPermissionDenied) {
        return;
      }

      final latitude = locationData.latitude;
      final longitude = locationData.longitude;
      if (latitude == null || longitude == null) {
        return;
      }

      _updateNearbySubscriptions(latitude, longitude);

      final now = DateTime.now();
      if (_lastLocationUpdateAt != null &&
          now.difference(_lastLocationUpdateAt!).inSeconds < 10) {
        return;
      }

      _lastLocationUpdateAt = now;

      final user = context.read<UserContext>().user;
      final userId = user?.id;
      if (userId == null || userId.isEmpty) {
        return;
      }

      try {
        await _realtimeLocationService.updateCurrentUserLocation(
          userId: userId,
          name: user?.name ?? 'User',
          profilePicture: user?.profilePicture,
          age: null,
          latitude: latitude,
          longitude: longitude,
        );
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          _rtdbPermissionDenied = true;
        }
      }
    });
  }

  void _updateNearbySubscriptions(double latitude, double longitude) {
    if (_rtdbPermissionDenied) {
      return;
    }

    final prefixes = _realtimeLocationService.getNearbyPrefixes(
      latitude,
      longitude,
    );

    final toRemove = _prefixSubscriptions.keys
        .where((prefix) => !prefixes.contains(prefix))
        .toList();
    for (final prefix in toRemove) {
      _prefixSubscriptions[prefix]?.cancel();
      _prefixSubscriptions.remove(prefix);
      final removedIds = _prefixUserIds.remove(prefix);
      if (removedIds != null) {
        for (final userId in removedIds) {
          _nearbyUsersById.remove(userId);
        }
      }
    }

    for (final prefix in prefixes) {
      if (_prefixSubscriptions.containsKey(prefix)) {
        continue;
      }

      _prefixSubscriptions[prefix] =
          _realtimeLocationService.listenToPrefix(prefix).listen((event) {
        final snapshot = event.snapshot.value;
        final currentUserId = context.read<UserContext>().user?.id;
        final updatedIds = <String>{};

        if (snapshot is Map) {
          snapshot.forEach((key, value) {
            final userId = key.toString();
            if (userId == currentUserId) {
              return;
            }

            if (value is Map) {
              updatedIds.add(userId);
              final userLocation = RealtimeUserLocation.fromMap(userId, value);
              _nearbyUsersById[userId] = userLocation;
            }
          });
        }

        final previousIds = _prefixUserIds[prefix] ?? <String>{};
        final removed = previousIds.difference(updatedIds);
        for (final userId in removed) {
          _nearbyUsersById.remove(userId);
        }

        _prefixUserIds[prefix] = updatedIds;

        if (mounted) {
          setState(() {});
        }
      }, onError: (error) {
        if (error.toString().contains('permission-denied')) {
          _rtdbPermissionDenied = true;
        }
      });
    }
  }

  Widget _buildCurrentLocationMarker(User? user) {
    final profileUrl = user?.profilePicture;
    final initials = _getUserInitials(user?.name ?? 'User');

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blue,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: profileUrl != null && profileUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: profileUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitialsFallback(initials),
                errorWidget: (context, url, error) => _buildInitialsFallback(initials),
              )
            : _buildInitialsFallback(initials),
      ),
    );
  }

  Widget _buildInitialsFallback(String initials) {
    return Container(
      color: AppColors.black,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getUserInitials(String fullName) {
    if (fullName.trim().isEmpty) {
      return 'U';
    }

    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    if (nameParts.length >= 2) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    }

    return nameParts[0][0].toUpperCase();
  }

  Widget _buildNearbyUserMarker(RealtimeUserLocation userLocation) {
    final profileUrl = userLocation.profilePicture;
    final initials = _getUserInitials(userLocation.name);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.black,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: profileUrl != null && profileUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: profileUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitialsFallback(initials),
                errorWidget: (context, url, error) =>
                    _buildInitialsFallback(initials),
              )
            : _buildInitialsFallback(initials),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) {
      return 'just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }

    final days = diff.inDays;
    return '${days}d ago';
  }


  @override
  Widget build(BuildContext context) {
    if (!widget.isMapInitialized) {
      return _buildMapSkeleton();
    }

    final userContext = context.watch<UserContext>();
    final user = userContext.user;
    final currentLocation = _liveLocation ?? widget.currentLocation;
    final fallbackLat = currentLocation?.latitude ?? 51.5074;
    final fallbackLng = currentLocation?.longitude ?? -0.1278;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Connections',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: widget.mapController,
                    options: MapOptions(
                      initialCenter: currentLocation != null
                          ? LatLng(currentLocation.latitude!, currentLocation.longitude!)
                          : const LatLng(51.5074, -0.1278), // London default
                      initialZoom: 13.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.smart_wristband',
                      ),
                      // 500m radius circle around current location
                      if (currentLocation != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(
                                currentLocation.latitude!,
                                currentLocation.longitude!,
                              ),
                              radius: 500, // 500 meters
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderColor: Colors.blue,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (currentLocation != null)
                            Marker(
                              width: 44,
                              height: 44,
                              point: LatLng(
                                currentLocation.latitude!,
                                currentLocation.longitude!,
                              ),
                              child: _buildCurrentLocationMarker(user),
                            ),
                          // 500m radius circle marker
                          if (currentLocation != null)
                            Marker(
                              width: 100,
                              height: 100,
                              point: LatLng(
                                currentLocation.latitude!,
                                currentLocation.longitude!,
                              ),
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ..._nearbyUsersById.values.map(
                            (userLocation) => Marker(
                              width: 40,
                              height: 40,
                              point: LatLng(
                                userLocation.latitude,
                                userLocation.longitude,
                              ),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _selectedUser = userLocation;
                                  });
                                },
                                child: _buildNearbyUserMarker(userLocation),
                              ),
                            ),
                          ),
                          Marker(
                            width: 40,
                            height: 40,
                            point: LatLng(
                              fallbackLat + 0.002,
                              fallbackLng - 0.002,
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _selectedUser = RealtimeUserLocation(
                                    userId: 'dummy_user',
                                    name: 'Test User',
                                    age: '24',
                                    latitude: fallbackLat + 0.002,
                                    longitude: fallbackLng - 0.002,
                                    lastUpdatedAt: DateTime.now(),
                                  );
                                });
                              },
                              child: _buildNearbyUserMarker(
                                RealtimeUserLocation(
                                  userId: 'dummy_user',
                                  name: 'Test User',
                                  age: '24',
                                  latitude: fallbackLat + 0.002,
                                  longitude: fallbackLng - 0.002,
                                  lastUpdatedAt: DateTime.now(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Landscape card for selected user
                if (_selectedUser != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                  _getUserInitials(_selectedUser!.name),
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          // User info
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedUser!.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedUser!.age ?? '--'} years old',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedUser!.lastUpdatedAt == null
                                      ? 'Last seen here'
                                      : 'Last seen ${_formatLastSeen(_selectedUser!.lastUpdatedAt!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Send Nudge button
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle nudge functionality
                                _sendNudgeSignal();
                                _handleSendNudge(_selectedUser!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Nudge sent to ${_selectedUser!.name}'),
                                    backgroundColor: AppColors.black,
                                  ),
                                );
                                setState(() {
                                  _selectedUser = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.black,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Send Nudge',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}