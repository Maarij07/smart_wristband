import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import '../utils/colors.dart';
import 'set_sos_pin_screen.dart';
import 'chat_screen.dart';
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
  const _HomeTabPage({super.key});

  @override
  State<_HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<_HomeTabPage> {
  // Wristband connection data
  bool _isConnected = true;
  String _deviceName = 'Smart Wristband Pro';
  String _relationshipStatus = 'Paired & Active';

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
                              // Navigate to pairing screen
                              Navigator.pop(context);
                              // In a real app, this would navigate to a pairing screen
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
                      'John Doe',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Device status indicator below welcome text
                    GestureDetector(
                      onTap: _showWristbandDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _isConnected
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.watch,
                                size: 20,
                                color: _isConnected
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isConnected
                                  ? 'Wristband Connected'
                                  : 'Wristband Disconnected',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _isConnected
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_down,
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
                    _buildStatCard('Connections', '12', Icons.people),
                    _buildStatCard('Online Now', '7', Icons.wifi),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Battery', '87%', Icons.battery_full),
                    _buildStatCard(
                      'Signal',
                      'Strong',
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
              children: [
                _buildActivityCard(
                  'SOS Alert Sent',
                  '10:15 PM',
                  Icons.warning,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                _buildActivityCard(
                  'New Connection',
                  'Yesterday',
                  Icons.person_add,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildActivityCard(
                  'Wristband Paired',
                  '2 days ago',
                  Icons.bluetooth_connected,
                  Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width:
          MediaQuery.of(context).size.width * 0.4 -
          20, // Half of 40% width minus padding
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
              color: color.withOpacity(0.1),
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
}

class _MessagesTabPage extends StatefulWidget {
  const _MessagesTabPage({super.key});

  @override
  State<_MessagesTabPage> createState() => _MessagesTabPageState();
}

class _MessagesTabPageState extends State<_MessagesTabPage> {
  // Sample chat data
  final List<Map<String, dynamic>> _chats = [
    {
      'id': 1,
      'name': 'Sarah Johnson',
      'avatar': Icons.person,
      'lastMessage': 'Hey, are you coming to the event tonight?',
      'time': '2:30 PM',
      'unreadCount': 2,
      'isOnline': true,
    },
    {
      'id': 2,
      'name': 'Michael Chen',
      'avatar': Icons.person,
      'lastMessage': 'Thanks for sharing the document!',
      'time': '11:45 AM',
      'unreadCount': 0,
      'isOnline': false,
    },
    {
      'id': 3,
      'name': 'Emma Wilson',
      'avatar': Icons.person,
      'lastMessage': 'See you tomorrow at 3pm',
      'time': 'Yesterday',
      'unreadCount': 1,
      'isOnline': true,
    },
  ];

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
            child: ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return Card(
                  color: AppColors.surfaceVariant,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.surface,
                          child: Icon(
                            chat['avatar'],
                            color: AppColors.black,
                            size: 20,
                          ),
                        ),
                        if (chat['isOnline'])
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chat['name'],
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          chat['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            chat['lastMessage'],
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (chat['unreadCount'] > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chat['unreadCount'].toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chat['id'],
                            chatName: chat['name'],
                            isOnline: chat['isOnline'],
                          ),
                        ),
                      );
                    },
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

class _MapsTabPage extends StatefulWidget {
  const _MapsTabPage({super.key});

  @override
  State<_MapsTabPage> createState() => _MapsTabPageState();
}

class _MapsTabPageState extends State<_MapsTabPage> {
  late MapController _mapController;
  LocationData? _currentLocation;
  bool _locationPermissionGranted = false;

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
      _locationPermissionGranted = true;
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
                                color: AppColors.black.withOpacity(0.05),
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
                                        color: AppColors.black.withOpacity(0.3),
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
                          color: AppColors.black.withOpacity(0.2),
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
  const _NudgesTabPage({super.key});

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
  const _ReceivedNudgesTab({super.key});

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
  const _SentNudgesTab({super.key});

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
  const _ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileTabContent();
  }
}

class _ProfileTabContent extends StatefulWidget {
  const _ProfileTabContent({super.key});

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
                'John Doe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                'john.doe@example.com',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    String value, {
    bool isEditable = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          if (isEditable)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: TextFormField(
                  initialValue: value,
                  decoration: InputDecoration(
                    hintText: value,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>(
    String label,
    T value,
    List<T> items,
    void Function(T?)? onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            items: items.map<DropdownMenuItem<T>>((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    item.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableList(String title, List<String> items) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '• \$item',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildConnectionCard(String title, String count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeSOSPinTabContent extends StatelessWidget {
  const _ChangeSOSPinTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Icon(Icons.lock, size: 40, color: AppColors.black),
          ),
          const SizedBox(height: 40),

          // Header
          Text(
            'Change SOS PIN',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Update your 4-digit emergency SOS PIN',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),

          // Change PIN button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to change PIN screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SetSOSPinScreen(),
                  ),
                );
              },
              style: AppColors.primaryButtonStyle(),
              child: Text(
                'Change PIN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
