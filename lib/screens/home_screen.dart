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
import 'user_profile_screen.dart';
import 'maps_tab.dart';
import 'messages_tab.dart';
import 'nudges_tab.dart';

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
    const MessagesTab(),
    MapsTab(
      mapController: _mapController, 
      locationService: _locationService,
      isMapInitialized: _isMapInitialized,
      currentLocation: _currentLocation,
    ),
    const NudgesTab(),
    const UserProfileScreen(),
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
          // Check if map controller is attached to a widget before moving
          try {
            _mapController.move(
              LatLng(location.latitude!, location.longitude!),
              15.0,
            );
          } catch (e) {
            // Map controller not ready yet, will initialize when map tab is opened
            print('Map controller not ready yet: $e');
          }
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
  // State for Find Me functionality
  bool _isFinding = false;
  
  // Wristband connection state
  bool _isConnected = false;
  String _deviceName = 'No device paired';
  String _relationshipStatus = 'Not paired';
  String _selectedRelationshipStatus = 'Private'; // New: track selected relationship status (default to Private)
  
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
        
        // Send audio notification signal when connected
        if (_isConnected) {
          _sendAudioNotification();
        }
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
    
    // Use the UserContext to check if SOS screen is already showing to prevent multiple instances
    final userContext = Provider.of<UserContext>(context, listen: false);
    print('Current isSosScreenShowing value: ${userContext.isSosScreenShowing}');
    
    if (userContext.isSosScreenShowing) {
      print('SOS screen already showing, ignoring duplicate signal');
      return;
    }
    
    // Set the flag in UserContext to indicate SOS screen is showing
    userContext.setIsSosScreenShowing(true);
    print('Set isSosScreenShowing to true');
    
    // Trigger emergency response
    // Navigate to emergency SOS screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SosAlertScreen()),
    ).then((_) {
      // Reset the flag when the screen is popped/closed
      print('SOS screen Navigator.then() callback executed');
      final userContext = Provider.of<UserContext>(context, listen: false);
      userContext.setIsSosScreenShowing(false);
      print('Reset isSosScreenShowing to false in Navigator callback');
    });
    
    // Note: Confirmation signal is now sent from SosAlertScreen after correct PIN is entered
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
    // List<Map<String, dynamic>> recentActivities = [];
    // if (healthMetrics != null) {
    //   var rawActivities = healthMetrics['recentActivities'] ?? [];
    //   recentActivities = rawActivities.map<Map<String, dynamic>>((activity) {
    //     return {
    //       'title': activity['title'],
    //       'time': activity['time'],
    //       'icon': _stringToIcon(activity['icon']),
    //       'color': _stringToColor(activity['color']),
    //     };
    //   }).toList();
    // }
    
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
                // Relationship Status Dropdown (disabled when not connected)
                IgnorePointer(
                  ignoring: !_isConnected, // Disable when not connected
                  child: Opacity(
                    opacity: _isConnected ? 1.0 : 0.5, // Dim when disabled
                    child: _buildRelationshipStatusDropdown(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Action Button for Find Me / Stop Find (toggle)
          IgnorePointer(
            ignoring: !_isConnected, // Disable when not connected
            child: Opacity(
              opacity: _isConnected ? 1.0 : 0.5, // Dim when disabled
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isFinding ? _stopFind : _findMe,
                  icon: Icon(_isFinding ? Icons.stop : Icons.search, size: 20),
                  label: Text(
                    _isFinding ? 'Stop Find' : 'Find Me',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isFinding ? Colors.red : Colors.blue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Method to send Find Me command to wristband
  void _findMe() async {
    try {
      print('? Find Me command triggered');
      setState(() {
        _isFinding = true;
      });
      
      await _sendFindCommand('?'); // '?' command to start continuous alarm
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Find Me command sent to wristband'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error sending Find Me command: $e');
      setState(() {
        _isFinding = false; // Reset on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send Find Me command'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Method to send Stop Find command to wristband
  void _stopFind() async {
    try {
      print('! Stop Find command triggered');
      setState(() {
        _isFinding = false;
      });
      
      await _sendFindCommand('!'); // '!' command to stop the alarm
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stop Find command sent to wristband'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error sending Stop Find command: $e');
      setState(() {
        _isFinding = true; // Reset on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send Stop Find command'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Method to send audio notification signal to wristband when connected
  Future<void> _sendAudioNotification() async {
    try {
      print('A Audio notification signal triggered on connection');
      await _sendFindCommand('A'); // 'A' command for audio notification
      
      if (mounted) {
        print('Audio notification sent to wristband');
      }
    } catch (e) {
      print('Error sending audio notification: $e');
    }
  }
  
  // Method to send Find/Stop commands using the same pattern as relationship status
  Future<void> _sendFindCommand(String command) async {
    try {
      // Send command to wristband using the same method as relationship status
      if (_outgoingDataCharacteristic != null) {
        List<int> commandBytes = utf8.encode(command);
        
        // Check which write method to use - use writeWithoutResponse like relationship status
        if (_outgoingDataCharacteristic!.properties.writeWithoutResponse) {
          await _outgoingDataCharacteristic!.write(commandBytes, withoutResponse: true);
          print('Sent Find BLE command (without response): $command');
        } else if (_outgoingDataCharacteristic!.properties.write) {
          await _outgoingDataCharacteristic!.write(commandBytes, withoutResponse: false);
          print('Sent Find BLE command (with response): $command');
        }
      } else {
        // Try to find the outgoing characteristic
        final userContext = Provider.of<UserContext>(context, listen: false);
        if (userContext.connectedDevice != null) {
          await _findAndSendCommand(userContext.connectedDevice!.id, command);
        }
      }
    } catch (e) {
      print('Error sending Find BLE command: $e');
      rethrow; // Re-throw to be caught by the calling methods
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
                    Text('Single (Yellow Light)'),
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
                    Text('Complicated (Green Light)'),
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





// Removed orphaned _MapsTabPageState class
  
