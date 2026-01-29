import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import '../utils/colors.dart';
import '../services/user_context.dart';

import 'sos_alert_screen.dart';
import 'signin_screen.dart';
import 'connect_wristband_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    const _HomeTabPage(),
    const _MessagesTabPage(),
    const _MapsTabPage(),
    _NudgesTabPage(), // Needs to be non-const due to TabController
    const _ProfileTabPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false, // Hide back button
        title: const SizedBox.shrink(), // Remove title
        toolbarHeight: 0, // Make toolbar invisible
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.black,
          unselectedItemColor: AppColors.textSecondary,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Maps',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Nudges',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabPage extends StatefulWidget {
  const _HomeTabPage();

  @override
  State<_HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<_HomeTabPage> {
  // Wristband connection state
  bool _isConnected = false;
  String _deviceName = 'No device paired';
  String _relationshipStatus = 'Not paired';
  
  // BLE subscription for incoming data
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<int>? _periodicSubscription;
  BluetoothCharacteristic? _incomingDataCharacteristic;
  
  @override
  void initState() {
    super.initState();
    // Initialize with context data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userContext = Provider.of<UserContext>(context, listen: false);
      if (userContext.connectedDevice != null) {
        setState(() {
          _isConnected = userContext.connectedDevice!.isConnected;
          _deviceName = userContext.connectedDevice!.name;
          _relationshipStatus = _isConnected ? 'Paired & Active' : 'Not paired';
        });
        
        // Set up BLE listener for incoming signals from wristband
        _setupBleListener(userContext.connectedDevice!.id);
      }
    });
  }
  
  void _setupBleListener(String deviceId) async {
    try {
      BluetoothDevice device = BluetoothDevice.fromId(deviceId);
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Look for the service that handles incoming data from the wristband
      BluetoothService? wristbandService = services.firstWhere(
        (service) => service.uuid.toString().toLowerCase().contains('fff0') || 
                       service.uuid.toString().toLowerCase().contains('custom') ||
                       service.uuid.toString().toLowerCase().contains('wristband'),
        orElse: () => services.first, // fallback to first service if none found
      );
      
      // Find the characteristic that receives data from the wristband
      _incomingDataCharacteristic = wristbandService.characteristics
          .firstWhere(
        (char) => char.properties.read || char.properties.notify,
        orElse: () => wristbandService.characteristics.firstWhere(
          (char) => char.properties.write,
          orElse: () => wristbandService.characteristics.first,
        ),
      );
      
      // Subscribe to notifications from the wristband
      if (_incomingDataCharacteristic!.properties.notify) {
        await _incomingDataCharacteristic!.setNotifyValue(true);
        _dataSubscription = _incomingDataCharacteristic!.lastValueStream.listen((data) {
          _handleIncomingSignal(data);
        });
      } else {
        // If notifications aren't available, periodically read the characteristic
        Stream.periodic(const Duration(seconds: 1)).listen((_) async {
          try {
            List<int> data = await _incomingDataCharacteristic!.read();
            _handleIncomingSignal(data);
          } catch (e) {
            print('Error reading characteristic: $e');
          }
        });
      }
      
      // Listen for connection state changes
      _connectionSubscription = device.connectionState.listen((state) {
        setState(() {
          _isConnected = state == BluetoothConnectionState.connected;
          _relationshipStatus = _isConnected ? 'Paired & Active' : 'Disconnected';
        });
      });
      
    } catch (e) {
      print('Error setting up BLE listener: $e');
    }
  }
  
  void _handleIncomingSignal(List<int> data) {
    // Convert bytes to string
    String signal = String.fromCharCodes(data);
    print('Received signal from wristband: $signal');
    
    // Process the incoming signal according to the protocol
    if (signal.startsWith('L')) {
      // Battery level signal (e.g., L87)
      String batteryLevel = signal.substring(1); // Remove 'L' prefix
      print('Battery level: ${batteryLevel}%');
      
      // Update user context with battery information
      final userContext = Provider.of<UserContext>(context, listen: false);
      // This would update the health metrics in the context
    } else if (signal.startsWith('R')) {
      // Status report signal (e.g., RS)
      String status = signal.substring(1); // Remove 'R' prefix
      print('Status report: $status');
      
      // Update status in UI
      setState(() {
        _relationshipStatus = status;
      });
    } else {
      // Process single character signals
      switch (signal) {
        case 'X': // SOS ALERT
          _handleSosAlert();
          break;
        case 'B': // Button Press
          _handleButtonPress();
          break;
        case 'O': // Power On
          print('Wristband powered on');
          setState(() {
            _relationshipStatus = 'Powered on';
          });
          break;
        case 'Z': // Power Off
          print('Wristband powered off');
          setState(() {
            _relationshipStatus = 'Powered off';
          });
          break;
        default:
          print('Unknown signal: $signal');
          break;
      }
    }
  }
  
  void _handleSosAlert() {
    print('SOS ALERT received from wristband!');
    // Trigger emergency response
    // Navigate to emergency SOS screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SosAlertScreen()),
    );
    
    // Send confirmation back to wristband
    final userContext = Provider.of<UserContext>(context, listen: false);
    userContext.confirmWristbandSos();
  }
  
  void _handleButtonPress() {
    print('Button press detected on wristband');
    // Handle button press event
    // Could trigger haptic feedback or update status
    final userContext = Provider.of<UserContext>(context, listen: false);
    userContext.triggerWristbandHaptic();
  }
  
  void _showWristbandDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          maxChildSize: 0.6,
          minChildSize: 0.3,
          initialChildSize: 0.4,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Handle indicator
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Wristband Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Device status card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  'Device Status',
                                  _isConnected ? 'Connected' : 'Disconnected',
                                  Icons.bluetooth_connected,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Device Name',
                                  _deviceName,
                                  Icons.devices_other,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Relationship Status',
                                  _relationshipStatus,
                                  Icons.link,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Action buttons
                          _buildActionButton(
                            'Disconnect',
                            Icons.bluetooth_disabled,
                            Colors.red,
                            () {
                              setState(() {
                                _isConnected = false;
                                _relationshipStatus = 'Disconnected';
                              });
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'Forget Device',
                            Icons.delete_forever,
                            Colors.orange,
                            () {
                              // Show confirmation dialog
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      'Forget Device',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to forget $_deviceName?',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isConnected = false;
                                            _deviceName = 'No device paired';
                                            _relationshipStatus = 'Not paired';
                                          });
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'Forget',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'Pair New Device',
                            Icons.bluetooth_searching,
                            AppColors.black,
                            () {
                              // Navigate to wristband connection screen
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ConnectWristbandScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: label == 'Device Status' && value == 'Connected'
                  ? Colors.green
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          side: BorderSide(color: color, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
    
  @override
  Widget build(BuildContext context) {
    final userContext = Provider.of<UserContext>(context);
    final user = userContext.user;
    // Wristband connection data from context
    String userNameFromContext = user?.name ?? 'User';
    
    // Get real stats from context
    var healthMetrics = userContext.getUserHealthMetrics();
    int connections = healthMetrics?['connections'] ?? 12; // Default to 12 if not available
    int onlineNow = healthMetrics?['onlineNow'] ?? 7; // Default to 7 if not available
    String batteryLevel = healthMetrics?['battery'] ?? '87%'; // Default to 87% if not available
    String signalStrength = healthMetrics?['signal'] ?? 'Strong'; // Default to Strong if not available
    
    // Get recent activities from context
    List<Map<String, dynamic>> recentActivities = [];
    if (healthMetrics != null) {
      var rawActivities = healthMetrics['recentActivities'] ?? [];
      recentActivities = rawActivities.map<Map<String, dynamic>>((activity) {
        return {
          'title': activity['title'],
          'time': activity['time'],
          'icon': _stringToIcon(activity['icon']),
          'color': _stringToColor(activity['color']),
        };
      }).toList();
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with watch icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Welcome section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning,',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      userNameFromContext, // Use real user name from context
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Device status indicator below welcome text
                    GestureDetector(
                      onTap: _deviceName != 'No device paired' ? _showWristbandDetails : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isConnected
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.watch,
                                    size: 24,
                                    color: _isConnected
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _deviceName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      _isConnected
                                          ? 'Connected'
                                          : 'Disconnected',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: _isConnected
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_deviceName != 'No device paired')
                              Icon(
                                Icons.keyboard_arrow_right,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Add new device button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConnectWristbandScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.add, size: 20),
                        label: Text(
                          'Add a new device',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Connection status section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Connections', connections.toString(), Icons.people), // Use real data
                    _buildStatCard('Online Now', onlineNow.toString(), Icons.wifi), // Use real data
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Battery', batteryLevel, Icons.battery_full), // Use real data
                    _buildStatCard(
                      'Signal',
                      signalStrength, // Use real data
                      Icons.signal_cellular_alt,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent activity
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Activity list
          Expanded(
            child: ListView(
              children: recentActivities.map((activity) {
                return _buildActivityCard(
                  activity['title'],
                  activity['time'],
                  activity['icon'],
                  activity['color'],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to convert string icon names to actual icons
  IconData _stringToIcon(String iconString) {
    switch (iconString) {
      case 'warning':
        return Icons.warning;
      case 'person_add':
        return Icons.person_add;
      case 'bluetooth_connected':
        return Icons.bluetooth_connected;
      case 'people':
        return Icons.people;
      case 'wifi':
        return Icons.wifi;
      case 'battery_full':
        return Icons.battery_full;
      case 'signal_cellular_alt':
        return Icons.signal_cellular_alt;
      default:
        return Icons.info;
    }
  }
  
  // Helper method to convert string color names to actual colors
  Color _stringToColor(String colorString) {
    switch (colorString) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
    
  Widget _buildStatCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 120, // Fixed width instead of using context
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.black),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    // Cancel all subscriptions
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _periodicSubscription?.cancel();
    
    // If we were listening for notifications, turn them off
    if (_incomingDataCharacteristic != null && _incomingDataCharacteristic!.properties.notify) {
      _incomingDataCharacteristic!.setNotifyValue(false);
    }
    
    super.dispose();
  }
}

class _MessagesTabPage extends StatelessWidget {
  const _MessagesTabPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messages',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your conversations will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapsTabPage extends StatefulWidget {
  const _MapsTabPage();

  @override
  State<_MapsTabPage> createState() => _MapsTabPageState();
}

class _MapsTabPageState extends State<_MapsTabPage> {
  late MapController _mapController;
  LocationData? _currentLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    // Check location permission
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    // Get current location
    locationData = await location.getLocation();

    setState(() {
      _currentLocation = locationData;
    });

    // Move map to current location
    if (locationData.latitude != null && locationData.longitude != null) {
      _mapController.move(
        LatLng(locationData.latitude!, locationData.longitude!),
        15.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation != null
                            ? LatLng(
                                _currentLocation!.latitude!,
                                _currentLocation!.longitude!,
                              )
                            : LatLng(51.5, -0.09), // Default to London
                        initialZoom: _currentLocation != null ? 15.0 : 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        if (_currentLocation != null) ...[
                          // 500m radius circle
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: LatLng(
                                  _currentLocation!.latitude!,
                                  _currentLocation!.longitude!,
                                ),
                                radius: 500, // 500 meters
                                color: AppColors.black.withValues(alpha: 0.05),
                                borderColor: AppColors.black,
                                borderStrokeWidth: 1,
                              ),
                            ],
                          ),
                          // Nearby dummy markers
                          MarkerLayer(
                            markers: [
                              // Dummy marker 1 - 200m northeast
                              Marker(
                                width: 30.0,
                                height: 30.0,
                                point: LatLng(
                                  _currentLocation!.latitude! + 0.0018,
                                  _currentLocation!.longitude! + 0.0018,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              // Dummy marker 2 - 300m southwest
                              Marker(
                                width: 30.0,
                                height: 30.0,
                                point: LatLng(
                                  _currentLocation!.latitude! - 0.0027,
                                  _currentLocation!.longitude! - 0.0027,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              // Dummy marker 3 - 400m east
                              Marker(
                                width: 30.0,
                                height: 30.0,
                                point: LatLng(
                                  _currentLocation!.latitude!,
                                  _currentLocation!.longitude! + 0.0036,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Custom themed location marker
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40.0,
                                height: 40.0,
                                point: LatLng(
                                  _currentLocation!.latitude!,
                                  _currentLocation!.longitude!,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.black,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.black.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Recenter button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.my_location,
                        color: AppColors.black,
                        size: 20,
                      ),
                      onPressed: _currentLocation != null
                          ? () {
                              _mapController.move(
                                LatLng(
                                  _currentLocation!.latitude!,
                                  _currentLocation!.longitude!,
                                ),
                                15.0,
                              );
                            }
                          : null,
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _NudgesTabPage extends StatefulWidget {
  const _NudgesTabPage();

  @override
  State<_NudgesTabPage> createState() => _NudgesTabPageState();
}

class _NudgesTabPageState extends State<_NudgesTabPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nudges',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider, width: 1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.black,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.black,
                    tabs: const [
                      Tab(text: 'Received'),
                      Tab(text: 'Sent'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                // Received nudges tab
                _ReceivedNudgesTab(),
                // Sent nudges tab
                _SentNudgesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedNudgesTab extends StatelessWidget {
  const _ReceivedNudgesTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Received',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4, // Sample received nudges
              itemBuilder: (context, index) {
                final users = [
                  {'name': 'Sarah Johnson', 'status': 'Online now'},
                  {'name': 'Michael Chen', 'status': 'Active 2h ago'},
                  {'name': 'Emma Wilson', 'status': 'Online now'},
                  {'name': 'David Brown', 'status': 'Active 30m ago'},
                ];

                return Card(
                  color: AppColors.surfaceVariant,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.black,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      users[index]['name']!,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      users[index]['status']!,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chat,
                            color: AppColors.black,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.favorite_border,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SentNudgesTab extends StatelessWidget {
  const _SentNudgesTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sent',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 3, // Sample sent nudges
              itemBuilder: (context, index) {
                final users = [
                  {'name': 'Alex Thompson', 'status': 'Pending response'},
                  {'name': 'Jessica Lee', 'status': 'Liked back'},
                  {'name': 'Ryan Miller', 'status': 'Pending response'},
                ];

                return Card(
                  color: AppColors.surfaceVariant,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.black,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      users[index]['name']!,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      users[index]['status']!,
                      style: TextStyle(
                        color: users[index]['status'] == 'Liked back'
                            ? AppColors.black
                            : AppColors.textSecondary,
                        fontWeight: users[index]['status'] == 'Liked back'
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: users[index]['status'] == 'Liked back'
                        ? Icon(Icons.favorite, color: Colors.red, size: 20)
                        : Icon(
                            Icons.access_time,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabPage extends StatelessWidget {
  const _ProfileTabPage();

  @override
  Widget build(BuildContext context) {
    return const _ProfileTabContent();
  }
}

class _ProfileTabContent extends StatefulWidget {
  const _ProfileTabContent();

  @override
  State<_ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends State<_ProfileTabContent> {
  String _relationshipStatus = 'Single';
  String _profileAccess = 'Anyone';
  String _locationAccess = 'Friends only';
  String _photoAccess = 'Friends only';

  @override
  Widget build(BuildContext context) {
    final userContext = Provider.of<UserContext>(context);
    final user = userContext.user;
    
    // Get user data from context
    String userName = user?.name ?? 'User';
    String userEmail = user?.email ?? 'user@example.com';
    
    return Column(
      children: [
        // Profile header section (sticky)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Column(
            children: [
              // Profile picture and edit icon
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: Icon(Icons.person, size: 40, color: AppColors.black),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Icon(Icons.edit, size: 16, color: AppColors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Display name
              Text(
                userName, // Use real user name from context
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                userEmail, // Use real user email from context
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // Relationship status row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Relationship Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _relationshipStatus,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                        ),
                        iconSize: 20,
                        elevation: 16,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        underline: Container(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _relationshipStatus = newValue!;
                          });
                        },
                        items:
                            <String>[
                              'Single',
                              'In a relationship',
                              'Married',
                              'Divorced',
                              'Widowed',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Information sections
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Profile heading
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Basic information section
                _buildSectionCard('Basic Information', [
                  _buildInfoRow('Phone', '+1 234 567 8900'),
                  _buildInfoRow(
                    'Bio',
                    'Software engineer passionate about technology and innovation',
                  ),
                ]),
                const SizedBox(height: 16),
                // About Me section with drawer-style expansion
                _buildDrawerSection('About Me', [
                  _buildDrawerItem(
                    'Interests',
                    'Technology, Travel, Photography, Cooking, Reading',
                    Icons.favorite,
                  ),
                  _buildDrawerItem(
                    'Dislikes',
                    'Noise, Rudeness, Punctuality issues, Littering',
                    Icons.thumb_down,
                  ),
                  _buildDrawerItem(
                    'Icebreakers',
                    'What\'s your favorite travel destination? What books are you reading? What\'s your hobby? What music do you enjoy? What are your weekend plans?',
                    Icons.question_answer,
                  ),
                ]),
                const SizedBox(height: 16),
                // Location section
                _buildSectionCard('Location', [
                  _buildInfoRow('City', 'New York'),
                  _buildInfoRow('State', 'NY'),
                  _buildInfoRow('Last Seen', 'Online now'),
                ]),
                const SizedBox(height: 16),
                // Social Media section
                _buildSectionCard('Social Media', [
                  _buildInfoRow('Instagram', '@johndoe'),
                  _buildInfoRow('Twitter', '@johndoe'),
                  _buildInfoRow('LinkedIn', 'linkedin.com/in/johndoe'),
                ]),
                const SizedBox(height: 16),
                // Privacy Settings section
                _buildSectionCard('Privacy Settings', [
                  _buildPrivacySettingRow('Profile Access', _profileAccess, (
                    String? newValue,
                  ) {
                    setState(() {
                      _profileAccess = newValue!;
                    });
                  }),
                  const SizedBox(height: 12),
                  _buildPrivacySettingRow('Location Access', _locationAccess, (
                    String? newValue,
                  ) {
                    setState(() {
                      _locationAccess = newValue!;
                    });
                  }),
                  const SizedBox(height: 12),
                  _buildPrivacySettingRow('Photo Access', _photoAccess, (
                    String? newValue,
                  ) {
                    setState(() {
                      _photoAccess = newValue!;
                    });
                  }),
                ]),
                const SizedBox(height: 16),
                // Social Connections section
                _buildSectionCard('Social Connections', [
                  _buildConnectionRow('Friends', '127'),
                  const SizedBox(height: 12),
                  _buildConnectionRow('Blocked Users', '3'),
                ]),
                const SizedBox(height: 24),
                // Sign out button
                _buildSignOutButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingRow(
    String label,
    String currentValue,
    void Function(String?) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              iconSize: 20,
              elevation: 16,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              underline: Container(),
              onChanged: onChanged,
              items: <String>['Anyone', 'Friends only', 'No one']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title, String content, IconData icon) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionRow(String label, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showSignOutConfirmation,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Sign Out',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performSignOut();
              },
              child: Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _performSignOut() {
    // Navigate to sign in screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }










}


