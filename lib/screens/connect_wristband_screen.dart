import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../utils/colors.dart';
import '../services/user_context.dart';
import 'home_screen.dart';

class ConnectWristbandScreen extends StatefulWidget {
  const ConnectWristbandScreen({super.key});

  @override
  State<ConnectWristbandScreen> createState() => _ConnectWristbandScreenState();
}

class _ConnectWristbandScreenState extends State<ConnectWristbandScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // BLE Variables
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
    initBle();
  }

  void initBle() {
    // Listen to scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    // Listen to bluetooth scanning state
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      setState(() {
        isScanning = scanning;
      });
    });
  }

  void startScan() async {
    try {
      // Check if Bluetooth is enabled first
      bool isBluetoothOn = await FlutterBluePlus.isSupported;
      if (!isBluetoothOn) {
        _showBluetoothDisabledDialog();
        return;
      }
      
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      // Handle specific Bluetooth disabled error
      if (e.toString().contains('Bluetooth must be turned on')) {
        _showBluetoothDisabledDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error starting scan: ${e.toString()}")),
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to start scan: $e")),
          );
        }
      }
    }
  }

  void _showBluetoothDisabledDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bluetooth Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.bluetooth_disabled,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Bluetooth is Turned Off',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  'Please turn on Bluetooth to scan for and connect to your wristband device.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.divider, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Turn On Bluetooth Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close the dialog
                          
                          try {
                            // Attempt to enable Bluetooth
                            await FlutterBluePlus.turnOn();
                            // Brief delay to allow Bluetooth to initialize
                            await Future.delayed(const Duration(milliseconds: 1000));
                            
                            // Start scanning in the parent widget
                            if (mounted) {
                              startScan();
                            }
                          } catch (e) {
                            // If we can't programmatically enable it, inform the user
                            // Note: We can't show a snackbar here since the dialog has been popped
                            // The parent widget should handle any necessary error display
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Turn On Bluetooth',
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
              ],
            ),
          ),
        );
      },
    );
  }

  void stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      // Error stopping scan: \$e
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      // Show connecting state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecting to ${device.platformName}...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Using free license for development/non-commercial use
      await device.connect(
        license: License.free,
        timeout: Duration(seconds: 15), // Increased timeout
        autoConnect: false,
      );
      
      setState(() {
        connectedDevice = device;
      });
      
      // Show success message
      if (mounted) {
        // Save device to context
        final userContext = Provider.of<UserContext>(context, listen: false);
        userContext.setConnectedDevice(Device(
          id: device.remoteId.toString(),
          name: device.platformName.isEmpty ? 'Unknown Device' : device.platformName,
          platformName: device.platformName,
          deviceType: 'Status Band',
          connectedAt: DateTime.now(),
          isConnected: true,
        ));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully connected to ${device.platformName}!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Wait a bit to show success message, then navigate
        await Future.delayed(Duration(seconds: 2));
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      // Error connecting to device: \$e
      
      // Show detailed error message
      String errorMessage = "Failed to connect";
      if (e.toString().contains("fbp-code 01")) {
        errorMessage = "Connection timeout - device may be out of range or not responding";
      } else if (e.toString().contains("fbp-code 10")) {
        errorMessage = "Device not advertising - make sure your wristband is in pairing mode";
      } else {
        errorMessage = "Failed to connect: ${e.toString()}";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
    stopScan();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top section with header and scan button
              FadeTransition(
                opacity: _opacityAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bluetooth Icon
                      Container(
                        width: 100,
                        height: 100,
                        margin: EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.bluetooth,
                          size: 48,
                          color: AppColors.black,
                        ),
                      ),

                      // Header
                      Text(
                        'Connect Your Wristband',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        'Scan nearby Bluetooth devices to find and connect to your Status Band',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Scan Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isScanning ? stopScan : startScan,
                          style: AppColors.primaryButtonStyle(),
                          child: Text(
                            isScanning ? 'Scanning...' : 'Scan for Devices',
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
                ),
              ),
              const SizedBox(height: 16),

              // Device List - Wrap in Expanded with explicit height constraints
              Expanded(
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: scanResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_searching,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isScanning
                                    ? 'Searching for devices...'
                                    : 'No devices found. Tap "Scan for Devices" to begin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: scanResults.length,
                          itemBuilder: (context, index) {
                            ScanResult result = scanResults[index];
                            return _buildDeviceCard(result);
                          },
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    // Skip connection and go to home
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.black,
                    side: BorderSide(color: AppColors.divider, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    'Connect Later',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(ScanResult result) {
    return Card(
      color: AppColors.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.device.platformName.isEmpty
                            ? 'Unknown Device'
                            : result.device.platformName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.device.remoteId.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // RSSI Signal Strength Indicator
                _buildRSSIIndicator(result.rssi),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => connectToDevice(result.device),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Connect',
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
          ],
        ),
      ),
    );
  }

  Widget _buildRSSIIndicator(int rssi) {
    Color signalColor;
    IconData signalIcon;
    String signalStrength;

    if (rssi >= -50) {
      signalColor = Colors.green;
      signalIcon = Icons.bluetooth_connected;
      signalStrength = 'Strong';
    } else if (rssi >= -70) {
      signalColor = Colors.orange;
      signalIcon = Icons.bluetooth;
      signalStrength = 'Medium';
    } else {
      signalColor = Colors.red;
      signalIcon = Icons.bluetooth_disabled;
      signalStrength = 'Weak';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(signalIcon, color: signalColor, size: 20),
        const SizedBox(height: 4),
        Text(
          '$rssi dBm',
          style: TextStyle(
            fontSize: 12,
            color: signalColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          signalStrength,
          style: TextStyle(
            fontSize: 10,
            color: signalColor,
          ),
        ),
      ],
    );
  }
}