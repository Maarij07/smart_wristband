import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  // Profile data
  String _name = 'Alex Johnson';
  String _email = 'alex.johnson@example.com';
  String _phoneNumber = '+1 (555) 123-4567';
  String _bio = 'Digital designer passionate about creating meaningful connections';
  String _relationshipStatus = 'Single';
  String _city = 'San Francisco';
  String _state = 'California';
  String _lastSeen = '2 hours ago';
  
  // Interests
  final List<String> _interests = ['Photography', 'Hiking', 'Coffee Culture', 'Art'];
  final List<String> _dislikes = ['Spicy food', 'Horror movies', 'Crowded places'];
  final List<String> _icebreakers = ['Ask me about my latest photo shoot', 'I love discovering hidden cafes'];
  
  // Social media
  final Map<String, String> _socialLinks = {
    'Instagram': '@alexjohnson',
    'Twitter': '@alexj_design',
    'LinkedIn': 'linkedin.com/in/alexjohnson'
  };
  
  // Privacy settings
  String _profileAccess = 'Friends Only';
  String _locationAccess = 'Friends Only';
  String _photoAccess = 'Friends Only';
  
  // Stats
  int _friendsCount = 127;
  int _blockedUsersCount = 3;
  
  // Relationship status options
  final List<String> _relationshipOptions = [
    'Single',
    'Committed',
    'Open to Friendship',
    'Complicated',
    'Married',
    'In a Relationship'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your personal information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Profile Card
              _buildProfileCard(),
              const SizedBox(height: 24),
              
              // Relationship Status Card
              _buildRelationshipCard(),
              const SizedBox(height: 24),
              
              // Basic Information Card
              _buildBasicInfoCard(),
              const SizedBox(height: 24),
              
              // Interests Card
              _buildInterestsCard(),
              const SizedBox(height: 24),
              
              // Location Card
              _buildLocationCard(),
              const SizedBox(height: 24),
              
              // Social Media Card
              _buildSocialMediaCard(),
              const SizedBox(height: 24),
              
              // Privacy Settings Card
              _buildPrivacyCard(),
              const SizedBox(height: 24),
              
              // Social Connections Card
              _buildConnectionsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.divider,
                backgroundImage: const NetworkImage(
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&h=200&fit=crop',
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.transparent,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEditableField('Name', _name, Icons.person),
          const SizedBox(height: 16),
          _buildEditableField('Email', _email, Icons.email),
        ],
      ),
    );
  }

  Widget _buildRelationshipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Relationship Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _relationshipStatus,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Phone', _phoneNumber, Icons.phone),
          const SizedBox(height: 16),
          _buildBioSection(),
        ],
      ),
    );
  }

  Widget _buildInterestsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Me',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTagSection('Interests', _interests, Icons.favorite),
          const SizedBox(height: 16),
          _buildTagSection('Dislikes', _dislikes, Icons.thumb_down),
          const SizedBox(height: 16),
          _buildTagSection('Icebreakers', _icebreakers, Icons.question_answer),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('City', _city, Icons.location_city),
          const SizedBox(height: 16),
          _buildInfoRow('State', _state, Icons.map),
          const SizedBox(height: 16),
          _buildInfoRow('Last Seen', _lastSeen, Icons.access_time),
        ],
      ),
    );
  }

  Widget _buildSocialMediaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Social Media',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._socialLinks.entries.map((entry) => _buildSocialRow(entry.key, entry.value)).toList(),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPrivacySetting(
            'Profile Access', 
            _profileAccess,
            ['Public', 'Friends Only', 'Private'],
            (newValue) => setState(() => _profileAccess = newValue),
          ),
          const SizedBox(height: 16),
          _buildPrivacySetting(
            'Location Access', 
            _locationAccess,
            ['Public', 'Friends Only', 'Private'],
            (newValue) => setState(() => _locationAccess = newValue),
          ),
          const SizedBox(height: 16),
          _buildPrivacySetting(
            'Photo Access', 
            _photoAccess,
            ['Public', 'Friends Only', 'Private'],
            (newValue) => setState(() => _photoAccess = newValue),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Social Connections',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildConnectionStat('Friends', _friendsCount, Icons.people),
          const SizedBox(height: 16),
          _buildConnectionStat('Blocked Users', _blockedUsersCount, Icons.block),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildEditableField(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const Icon(
          Icons.edit,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              'Bio: ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Text(
            _bio,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              '$title: ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => _buildTag(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSocialRow(String platform, String handle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          Text(
            '$platform: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              handle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(
            Icons.link,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySetting(String setting, String value, List<String> options, Function(String) onChanged) {
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  setting,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ...options.map((option) => _buildOptionTile(option, value, (newValue) {
                  Navigator.pop(context, newValue);
                })).toList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
        
        if (selected != null) {
          onChanged(selected);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            setting,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String option, String currentValue, Function(String) onChanged) {
    final isSelected = option == currentValue;
    return GestureDetector(
      onTap: () => onChanged(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              option,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                size: 20,
                color: AppColors.white,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStat(String label, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}