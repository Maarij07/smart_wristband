import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'set_sos_pin_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                tabs: [
                  Tab(text: 'Profile'),
                  Tab(text: 'Change SOS PIN'),
                ],
              ),
            ),
            // Tab bar view
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Profile tab
                  _buildProfileTab(),
                  // Change SOS PIN tab
                  _buildChangeSOSPinTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.divider,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // User info
          Text(
            'John Doe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'john.doe@example.com',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Profile fields
          _buildProfileField('Full Name', 'John Doe'),
          const SizedBox(height: 16),
          _buildProfileField('Email', 'john.doe@example.com'),
          const SizedBox(height: 16),
          _buildProfileField('Phone', '+1 234 567 8900'),
          const SizedBox(height: 16),
          _buildProfileField('Emergency Contact', '+1 234 567 8901'),
        ],
      ),
    );
  }

  Widget _buildChangeSOSPinTab() {
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
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.lock,
              size: 40,
              color: AppColors.black,
            ),
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

  Widget _buildProfileField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
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
}