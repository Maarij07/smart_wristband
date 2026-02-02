import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import '../utils/colors.dart';
import '../services/user_context.dart';
import '../services/location_service.dart';
import 'sos_alert_screen.dart';

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
  Map<String, String>? _selectedUser;
  BluetoothCharacteristic? _outgoingDataCharacteristic; // Added for sending commands
  
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
  Widget build(BuildContext context) {
    if (!widget.isMapInitialized) {
      return _buildMapSkeleton();
    }
    
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
              // Emergency SOS button
              FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SosAlertScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icon(Icons.warning, size: 20),
                label: Text(
                  'SOS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
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
                      initialCenter: widget.currentLocation != null
                          ? LatLng(widget.currentLocation!.latitude!, widget.currentLocation!.longitude!)
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
                      if (widget.currentLocation != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(
                                widget.currentLocation!.latitude!,
                                widget.currentLocation!.longitude!,
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
                          if (widget.currentLocation != null)
                            Marker(
                              width: 20,
                              height: 20,
                              point: LatLng(
                                widget.currentLocation!.latitude!,
                                widget.currentLocation!.longitude!,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          // 500m radius circle marker
                          if (widget.currentLocation != null)
                            Marker(
                              width: 100,
                              height: 100,
                              point: LatLng(
                                widget.currentLocation!.latitude!,
                                widget.currentLocation!.longitude!,
                              ),
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
                          // Dummy girl markers within 500m radius
                          if (widget.currentLocation != null)
                            Marker(
                              width: 40,
                              height: 40,
                              point: LatLng(
                                widget.currentLocation!.latitude! + 0.003, // Approximately 300m North
                                widget.currentLocation!.longitude!,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedUser = {
                                      'name': 'Emma Watson',
                                      'age': '28',
                                      'avatar': 'EW',
                                    };
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.pink,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          if (widget.currentLocation != null)
                            Marker(
                              width: 40,
                              height: 40,
                              point: LatLng(
                                widget.currentLocation!.latitude!,
                                widget.currentLocation!.longitude! + 0.004, // Approximately 300m East
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedUser = {
                                      'name': 'Sophia Turner',
                                      'age': '25',
                                      'avatar': 'ST',
                                    };
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
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
                                _selectedUser!['avatar']!,
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
                                  _selectedUser!['name']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedUser!['age']! + ' years old',
                                  style: TextStyle(
                                    fontSize: 14,
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Nudge sent to ' + _selectedUser!['name']!),
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