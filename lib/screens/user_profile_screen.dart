import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../services/user_context.dart';
import 'set_sos_pin_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userContext = Provider.of<UserContext>(context);
    final user = userContext.user;
    
    if (user == null) {
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
        body: const Center(child: Text('User not found')),
      );
    }

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
                  _buildProfileTab(user),
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

  Widget _buildProfileTab(User user) {
    _bioController.text = user.bio ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    
    // Extract social media links if available
    if (user.socialMediaLinks != null) {
      _instagramController.text = user.socialMediaLinks!['instagram'] ?? '';
      _twitterController.text = user.socialMediaLinks!['twitter'] ?? '';
      _linkedinController.text = user.socialMediaLinks!['linkedin'] ?? '';
    }
    
    return SingleChildScrollView(
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
            user.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Profile fields
          _buildProfileField('Full Name', user.name),
          const SizedBox(height: 16),
          _buildProfileField('Email', user.email),
          const SizedBox(height: 16),
          
          // Phone field
          _buildEditableField(
            'Phone',
            user.phoneNumber ?? 'Not added',
            _phoneController,
            TextInputType.phone,
            (value) async {
              // Update phone in both context and Firebase
              final userContext = Provider.of<UserContext>(context, listen: false);
              await userContext.updateUserProfile(
                phoneNumber: value.isNotEmpty ? value : null,
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Relationship Status
          _buildProfileField('Relationship Status', user.relationshipStatus ?? 'Single'),
          const SizedBox(height: 16),
          
          // Bio field with character counter
          _buildBioField(),
          const SizedBox(height: 16),
          
          // Social Media Links Section
          _buildSocialMediaSection(),
          const SizedBox(height: 16),
          
          // Privacy Settings Section
          _buildPrivacySettingsSection(),
          const SizedBox(height: 16),
          
          // Social Connections Section
          _buildSocialConnectionsSection(),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, String currentValue, TextEditingController controller, TextInputType keyboardType, Future<void> Function(String) onSave) {
    bool isEditing = currentValue == 'Not added' || currentValue.isEmpty;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: isEditing
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      hintText: 'Enter $label',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.black, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      onSave(value);
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentValue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          controller.text = currentValue;
                          // Show dialog to edit
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Edit $label'),
                                content: TextField(
                                  controller: controller,
                                  keyboardType: keyboardType,
                                  decoration: InputDecoration(hintText: 'Enter $label'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await onSave(controller.text);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioField() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Bio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextField(
            controller: _bioController,
            maxLines: 3,
            maxLength: 500,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'Tell us about yourself...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.black, width: 2),
              ),
            ),
            onChanged: (value) async {
              // Update bio in both context and Firebase
              final userContext = Provider.of<UserContext>(context, listen: false);
              await userContext.updateUserProfile(
                bio: value.isNotEmpty ? value : null,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${_bioController.text.length}/500',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          'Social Media',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.black),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSocialMediaField(
                  'Instagram',
                  _instagramController,
                  r'^https?://(www\.)?instagram\.com/.+',
                  Icons.camera_alt_outlined,
                ),
                const SizedBox(height: 16),
                _buildSocialMediaField(
                  'Twitter',
                  _twitterController,
                  r'^https?://(www\.)?twitter\.com/.+|https?://(www\.)?x\.com/.+',
                  Icons.tag,
                ),
                const SizedBox(height: 16),
                _buildSocialMediaField(
                  'LinkedIn',
                  _linkedinController,
                  r'^https?://(www\.)?linkedin\.com/in/.+',
                  Icons.business_center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaField(String platform, TextEditingController controller, String regex, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                platform,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Paste $platform link',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.black, width: 2),
              ),
            ),
            onChanged: (value) async {
              if (value.isNotEmpty && !RegExp(regex).hasMatch(value)) {
                // Show error if URL doesn't match the expected pattern
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid $platform URL format'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                // Update social media links in both context and Firebase
                final userContext = Provider.of<UserContext>(context, listen: false);
                final currentUser = userContext.user!;
                final updatedLinks = {
                  ...(currentUser.socialMediaLinks ?? {}),
                  platform.toLowerCase(): value.isNotEmpty ? value : null,
                }..removeWhere((key, value) => value == null);
                
                await userContext.updateUserProfile(
                  socialMediaLinks: updatedLinks.isEmpty ? null : updatedLinks,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          'Privacy Settings',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.black),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPrivacySettingRow('Profile Access', 'Anyone'),
                const Divider(height: 24),
                _buildPrivacySettingRow('Location Access', 'Friends Only'),
                const Divider(height: 24),
                _buildPrivacySettingRow('Photo Access', 'Friends Only'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingRow(String setting, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(setting, style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSocialConnectionsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          'Social Connections',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.black),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildConnectionCountRow('Friends', '0'),
                const Divider(height: 24),
                _buildConnectionCountRow('Blocked', '0'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCountRow(String type, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type, style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
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
}