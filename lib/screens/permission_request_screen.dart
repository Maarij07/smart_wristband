import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/colors.dart';
import '../services/permission_service.dart';
import 'signin_screen.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool _isProcessing = false;
  bool _allPermissionsGranted = false;
  Map<String, bool> _permissionResults = {};

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  void _checkInitialPermissions() async {
    final locationGranted = await PermissionService.isLocationPermissionGranted();
    final notificationGranted = await PermissionService.isNotificationPermissionGranted();
    
    setState(() {
      _allPermissionsGranted = locationGranted && notificationGranted;
      _permissionResults['location'] = locationGranted;
      _permissionResults['notification'] = notificationGranted;
    });
    
    if (_allPermissionsGranted) {
      // If all permissions are already granted, navigate to sign in
      _navigateToSignIn();
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Request location permission if not granted
      if (!(_permissionResults['location'] ?? false)) {
        final locationResult = await PermissionService.requestLocationPermission();
        setState(() {
          _permissionResults['location'] = locationResult;
        });
      }
      
      // Request notification permission if not granted
      if (!(_permissionResults['notification'] ?? false)) {
        final notificationResult = await PermissionService.requestNotificationPermission();
        setState(() {
          _permissionResults['notification'] = notificationResult;
        });
      }
      
      setState(() {
        _allPermissionsGranted = (_permissionResults['location'] ?? false) && 
                                (_permissionResults['notification'] ?? false);
        _isProcessing = false;
      });

      if (_allPermissionsGranted) {
        // All permissions granted, navigate to sign in
        _navigateToSignIn();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  void _navigateToSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Error', style: TextStyle(color: AppColors.textPrimary)),
          content: Text(error, style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: AppColors.black)),
            ),
          ],
        );
      },
    );
  }

  void _openAppSettings() {
    PermissionService.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
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
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.privacy_tip,
                  size: 40,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 40),

              // Title
              Text(
                'Permissions Required',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'We need a few permissions to provide the best experience',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              // Permissions list
              _buildPermissionItem(
                Icons.location_on,
                'Location Access',
                'To find nearby connections and show you on the map',
                _permissionResults['location'] ?? false,
              ),
              const SizedBox(height: 16),

              _buildPermissionItem(
                Icons.notifications,
                'Notifications',
                'To alert you about important updates and messages',
                _permissionResults['notification'] ?? false,
              ),
              const SizedBox(height: 16),


              const SizedBox(height: 40),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _requestPermissions,
                  style: AppColors.primaryButtonStyle(),
                  child: _isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          _allPermissionsGranted ? 'Continue' : 'Allow Permissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip option
              TextButton(
                onPressed: _allPermissionsGranted ? _navigateToSignIn : null,
                child: Text(
                  'Continue without permissions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _allPermissionsGranted ? AppColors.black : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description, bool isGranted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? Colors.green.withOpacity(0.3) : AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isGranted ? Colors.green.withOpacity(0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isGranted ? Colors.green : AppColors.divider,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isGranted ? Colors.green : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isGranted)
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
        ],
      ),
    );
  }
}