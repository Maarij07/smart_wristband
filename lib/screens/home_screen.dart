import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';
import '../utils/colors.dart';
import '../services/user_context.dart';
import '../services/location_service.dart';

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
  late MapController _mapController; // Persistent map controller
  final LocationService _locationService = LocationService();
  bool _isMapInitialized = false; // Track map initialization state
  LocationData? _currentLocation; // Cache current location
  
  List<Widget> get _pages => [
    const _HomeTabPage(),
    const _MessagesTabPage(),
    _MapsTabPage(
      mapController: _mapController, 
      locationService: _locationService,
      isMapInitialized: _isMapInitialized,
      currentLocation: _currentLocation,
    ),
    _NudgesTabPage(), // Needs to be non-const due to TabController
    const _ProfileTabPage(),
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Initialize location service early
    _locationService.initialize();
    // Initialize map once
    _initializeMapOnce();
  }
  
  Future<void> _initializeMapOnce() async {
    if (_isMapInitialized) return; // Already initialized
    
    // Get location from service (cached or fresh)
    final location = await _locationService.getCurrentLocation();
    
    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
        _isMapInitialized = true;
      });
      
      // Move map to current location after widget is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isMapInitialized) {
          _mapController.move(
            LatLng(location.latitude!, location.longitude!),
            15.0,
          );
        }
      });
    } else {
      setState(() {
        _isMapInitialized = true; // Mark as initialized even if no location
      });
    }
  }

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
  String _selectedRelationshipStatus = 'Single'; // New: track selected relationship status
  
  // BLE subscription for incoming data
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<int>? _periodicSubscription;
  BluetoothCharacteristic? _incomingDataCharacteristic;
  BluetoothCharacteristic? _outgoingDataCharacteristic; // Added for sending commands
  
  @override
  void initState() {
    super.initState();
    // Initialize with context data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSetupConnection();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check connection whenever dependencies change
    _checkAndSetupConnection();
  }
  
  void _checkAndSetupConnection() {
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
  }
  
  void _setupBleListener(String deviceId) async {
    try {
      BluetoothDevice device = BluetoothDevice.fromId(deviceId);
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // YOUR WRISTBAND'S ACTUAL SERVICE UUID
      const String wristbandServiceUuid = '12345678-04d2-162e-04d2-56789abcdef0';
      const String wristbandNotifyCharUuid = '12345678-04d2-162e-04d2-56789abcdef2';
      const String wristbandWriteCharUuid = '12345678-04d2-162e-04d2-56789abcdef1';
      
      // Find your wristband's service
      BluetoothService? wristbandService;
      try {
        wristbandService = services.firstWhere(
          (service) => service.uuid.toString().toLowerCase() == wristbandServiceUuid,
        );
        print('✓ Found wristband service for listening: ${wristbandService.uuid}');
      } catch (e) {
        print('❌ Could not find wristband service');
        return;
      }
      
      // Find the NOTIFY characteristic (for receiving data FROM wristband)
      try {
        _incomingDataCharacteristic = wristbandService.characteristics.firstWhere(
          (char) => char.uuid.toString().toLowerCase() == wristbandNotifyCharUuid,
        );
        print('✓ Found notify characteristic: ${_incomingDataCharacteristic!.uuid}');
      } catch (e) {
        print('❌ Could not find notify characteristic');
      }
      
      // Find the WRITE characteristic (for sending data TO wristband)
      try {
        _outgoingDataCharacteristic = wristbandService.characteristics.firstWhere(
          (char) => char.uuid.toString().toLowerCase() == wristbandWriteCharUuid,
        );
        print('✓ Found write characteristic: ${_outgoingDataCharacteristic!.uuid}');
      } catch (e) {
        print('❌ Could not find write characteristic');
      }
      
      // Subscribe to notifications from the wristband
      if (_incomingDataCharacteristic != null && 
          _incomingDataCharacteristic!.properties.notify) {
        await _incomingDataCharacteristic!.setNotifyValue(true);
        print('✓ Enabled notifications on wristband');
        
        _dataSubscription = _incomingDataCharacteristic!.lastValueStream.listen((data) {
          _handleIncomingSignal(data);
        });
      } else {
        print('⚠️ Notify characteristic not available or does not support notifications');
      }
      
      // Listen for connection state changes
      _connectionSubscription = device.connectionState.listen((state) {
        setState(() {
          _isConnected = state == BluetoothConnectionState.connected;
          _relationshipStatus = _isConnected ? 'Paired & Active' : 'Disconnected';
        });
        print('Connection state changed: ${_isConnected ? "Connected" : "Disconnected"}');
      });
      
    } catch (e) {
      print('❌ Error setting up BLE listener: $e');
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
      userContext.updateDeviceBatteryLevel('${batteryLevel}%');
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
                          if (_isConnected)
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
                            )
                          else
                            _buildActionButton(
                              'Reconnect',
                              Icons.bluetooth_connected,
                              Colors.green,
                              _reconnectToDevice,
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
                const SizedBox(height: 20),
                // Relationship Status Dropdown
                _buildRelationshipStatusDropdown(),
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
  
  Widget _buildRelationshipStatusDropdown() {
    return Container(
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
          Text(
            'Relationship Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedRelationshipStatus,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.black, width: 2),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'Single',
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text('Single (Green Light)'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'Taken',
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text('Taken (Red Light)'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'Complicated',
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.yellow, size: 16),
                    const SizedBox(width: 8),
                    Text('Complicated (Yellow Light)'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'Private',
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Text('Private (No Light)'),
                  ],
                ),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedRelationshipStatus = newValue;
                });
                
                // Update in Firebase and send BLE command
                _updateRelationshipStatus(newValue);
              }
            },
          ),
        ],
      ),
    );
  }
  
  void _updateRelationshipStatus(String status) async {
    try {
      // Update in UserContext (which will sync to Firebase)
      final userContext = Provider.of<UserContext>(context, listen: false);
      await userContext.updateUserProfile(relationshipStatus: status);
      
      // Send BLE command to wristband
      await _sendBleCommand(status);
      
      print('Relationship status updated to: $status');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relationship status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating relationship status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update relationship status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _sendBleCommand(String status) async {
    try {
      // Map relationship status to BLE command
      String command;
      switch (status) {
        case 'Single':
          command = 'S'; // Set Single - Green light
          break;
        case 'Taken':
          command = 'T'; // Set Taken - Red light
          break;
        case 'Complicated':
          command = 'C'; // Set Complicated - Yellow light
          break;
        case 'Private':
          command = 'P'; // Set Private - No light
          break;
        default:
          command = 'P'; // Default to Private
      }
      
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
  
  Future<void> _reconnectToDevice() async {
    try {
      final userContext = Provider.of<UserContext>(context, listen: false);
      if (userContext.connectedDevice == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No device to reconnect to'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final deviceId = userContext.connectedDevice!.id;
      BluetoothDevice device = BluetoothDevice.fromId(deviceId);
      
      // Show connecting status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connecting to device...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      // Attempt to connect
      await device.connect(
        license: License.free,
        timeout: Duration(seconds: 15),
        autoConnect: false,
      );
      
      // Update UI state
      setState(() {
        _isConnected = true;
        _deviceName = userContext.connectedDevice!.name;
        _relationshipStatus = 'Connected';
      });
      
      // Set up BLE listeners again
      _setupBleListener(deviceId);
      
      if (mounted) {
        Navigator.pop(context); // Close the drawer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully reconnected to ${_deviceName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      print('Successfully reconnected to device: $_deviceName');
    } catch (e) {
      print('Error reconnecting to device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reconnect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
  final MapController mapController;
  final LocationService locationService;
  final bool isMapInitialized;
  final LocationData? currentLocation;

  const _MapsTabPage({
    required this.mapController,
    required this.locationService,
    required this.isMapInitialized,
    required this.currentLocation,
  });

  @override
  State<_MapsTabPage> createState() => _MapsTabPageState();
}

class _MapsTabPageState extends State<_MapsTabPage> {
  
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
            child: ClipRRect(
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
                    ],
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
                              'Complicated',
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


