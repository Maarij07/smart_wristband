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
import '../services/ble_connection_provider.dart';

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
  DateTime? _lastSosClearedTime; // Track when SOS was last cleared for debounce
  
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
  
  // Track relationship status selection locally for UI
  String _selectedRelationshipStatus = 'Private'; 
  
  // Flag to track if SOS route is currently valid/pushed to avoid double pushes
  bool _isSosRouteActive = false;
  
  BleConnectionProvider? _bleProvider;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to BLE provider state changes
    final provider = Provider.of<BleConnectionProvider>(context, listen: false);
    if (_bleProvider != provider) {
      _bleProvider?.removeListener(_onBleStateChanged);
      _bleProvider = provider;
      _bleProvider?.addListener(_onBleStateChanged);
    }
  }
  
  @override
  void dispose() {
    _bleProvider?.removeListener(_onBleStateChanged);
    super.dispose();
  }
  
  void _onBleStateChanged() {
    if (_bleProvider == null) return;
    
    // Check if we need to navigate to SOS screen
    if (_bleProvider!.isSosScreenActive && !_isSosRouteActive) {
      _navigateToSosScreen();
    }
  }
  
  void _navigateToSosScreen() {
    _isSosRouteActive = true;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SosAlertScreen(
          onSosCleared: () async {
            // When user clears SOS, tell provider to send 'K' and reset state
            if (_bleProvider != null) {
              await _bleProvider!.clearSos();
            }
          },
        ),
      ),
    ).then((_) {
      // Reset local route flag when screen is closed
      _isSosRouteActive = false;
      
      // Safety: ensure provider state is reset if closed via other means (back button)
      // If clearSos was called, it's already false. If not, we might need to reset it.
      // But normally SosAlertScreen insists on clearing or we assume handled.
      // If the user forcibly backs out without clearing, the state remains active in provider 
      // preventing re-trigger. This is likely desired behavior until properly cleared?
      // For now, let's assume onSosCleared (which calls clearSos) is the primary exit.
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Access providers
    final userContext = Provider.of<UserContext>(context);
    final bleProvider = Provider.of<BleConnectionProvider>(context);
    
    final user = userContext.user;
    String userNameFromContext = user?.name ?? 'User';
    
    // Status metrics from provider logic
    bool isConnected = bleProvider.isConnected;
    
    // Use UserContext health metrics (which should be updated by BleProvider in a real app)
    // For now we trust UserContext or mock
    var healthMetrics = userContext.getUserHealthMetrics();
    int connections = healthMetrics?['connections'] ?? 12;
    int onlineNow = healthMetrics?['onlineNow'] ?? 7;
    String batteryLevel = healthMetrics?['battery'] ?? '87%';
    String signalStrength = isConnected ? 'Strong' : 'Disconnected';
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            // Manual SOS trigger via Provider
            bleProvider.triggerManualSos();
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.sos, color: Colors.white),
      ),
      body: Padding(
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
                      userNameFromContext,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Device status indicator
                    GestureDetector(
                      onTap: () {
                         if (!isConnected) {
                           _startConnectionProcess(context);
                         } else {
                           // Show details
                           _showWristbandDetails(context, bleProvider);
                         }
                      },
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
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.watch,
                                    color: AppColors.black,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Device Status',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      isConnected ? 'Connected' : 'Disconnected',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isConnected ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textSecondary,
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
            
            const SizedBox(height: 24),
            
            // Grid of Stat Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard('Connections', connections.toString(), Icons.people),
                  _buildStatCard('Online Now', onlineNow.toString(), Icons.wifi),
                  _buildStatCard('Battery', batteryLevel, Icons.battery_full),
                  _buildStatCard(
                    'Signal', 
                    signalStrength, 
                    Icons.signal_cellular_alt,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Relationship Status Dropdown
            _buildRelationshipDropdown(bleProvider, userContext),
            
            const SizedBox(height: 24),

            // Quick Action Button for Find Me
            IgnorePointer(
              ignoring: !isConnected, 
              child: Opacity(
                opacity: isConnected ? 1.0 : 0.5, 
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleFindMe(bleProvider),
                    icon: Icon(_isFinding ? Icons.stop : Icons.search, size: 20),
                    label: Text(
                      _isFinding ? 'Stop Find' : 'Find Me', 
                      style: const TextStyle(
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
      ),
    );
  }
  
  Widget _buildRelationshipDropdown(BleConnectionProvider bleProvider, UserContext userContext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Relationship Status',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRelationshipStatus,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: [
                DropdownMenuItem(
                  value: 'Single',
                  child: Row(
                    children: const [
                      Icon(Icons.circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text('Single (Green Light)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Taken',
                  child: Row(
                    children: const [
                      Icon(Icons.circle, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Taken (Red Light)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Complicated',
                  child: Row(
                    children: const [
                      Icon(Icons.circle, color: Colors.yellow, size: 16),
                      SizedBox(width: 8),
                      Text('Complicated (Yellow Light)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Private',
                  child: Row(
                    children: const [
                      Icon(Icons.circle, color: Colors.grey, size: 16),
                      SizedBox(width: 8),
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
                  _updateRelationshipStatus(newValue, bleProvider, userContext);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _updateRelationshipStatus(String status, BleConnectionProvider bleProvider, UserContext userContext) async {
      // Update UserContext
      await userContext.updateUserProfile(relationshipStatus: status);
      
      // Determine command
      String command = 'P';
      switch (status) {
        case 'Single': command = 'S'; break;
        case 'Taken': command = 'T'; break;
        case 'Complicated': command = 'C'; break;
        case 'Private': command = 'P'; break;
      }
      
      // Send via provider
      try {
        await bleProvider.sendData(command);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $status'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        print('Error updating status: $e');
      }
  }
  
  void _toggleFindMe(BleConnectionProvider bleProvider) async {
    setState(() => _isFinding = !_isFinding);
    try {
      if (_isFinding) {
        await bleProvider.sendData('?'); 
      } else {
        await bleProvider.sendData('!'); 
      }
    } catch (e) {
      print('Error checking find me: $e');
    }
  }
  
  void _startConnectionProcess(BuildContext context) {
      final userContext = Provider.of<UserContext>(context, listen: false);
      if (userContext.connectedDevice != null) {
          Provider.of<BleConnectionProvider>(context, listen: false)
            .connectToDevice(userContext.connectedDevice!.id);
      } else {
         Navigator.push(
           context, 
           MaterialPageRoute(builder: (context) => const ConnectWristbandScreen()),
         );
      }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.black, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showWristbandDetails(BuildContext context, BleConnectionProvider bleProvider) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Device Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.bluetooth_connected),
                title: Text(bleProvider.device?.platformName ?? 'Unknown'),
                subtitle: Text(bleProvider.device?.remoteId.toString() ?? ''),
              ),
              ElevatedButton(
                onPressed: () {
                  bleProvider.disconnect();
                  Navigator.pop(ctx);
                },
                child: Text('Disconnect'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
      );
  }
}
