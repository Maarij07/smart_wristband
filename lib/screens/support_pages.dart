import 'package:flutter/material.dart';
import '../utils/colors.dart';

// FAQs Page
class FAQsPage extends StatelessWidget {
  const FAQsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFAQItem(
              'How do I update my profile?',
              'You can update your profile information by going to the Profile tab. Tap on your avatar to change your profile picture, and edit your personal information directly from the profile page.',
            ),
            _buildFAQItem(
              'How do I send a nudge to someone?',
              'Open the Maps tab to see nearby connections. Tap on a user marker to select them, then click the "Send Nudge" button. A nudge will also be sent via Bluetooth to your wristband.',
            ),
            _buildFAQItem(
              'What does the relationship status do?',
              'Your relationship status is displayed to other users and affects your wristband LED indicator: Green (Single), Red (Taken), Yellow (Complicated), or Grey (Private).',
            ),
            _buildFAQItem(
              'How do I manage my location sharing?',
              'Location sharing is automatic when you\'re logged in. Your location is updated every 10 seconds and shared only with users within 500m of you. You can disable location by signing out.',
            ),
            _buildFAQItem(
              'Can I send attachments in messages?',
              'Yes! In the chat screen, tap the attachment button to upload photos, videos, or audio files. Your attachments are stored securely in Firebase Storage.',
            ),
            _buildFAQItem(
              'How do I record audio in chat?',
              'In the chat screen, tap the attachment button and select "Audio". Press Record to start, Stop to finish, and Preview to hear it before sending.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Terms & Conditions Page
class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Agreement',
              'By accessing and using Smart Wristband, you accept and agree to be bound by the terms and provision of this agreement. Smart Wristband provides a platform for real-time location sharing and communication. If you do not agree to abide by the above, please do not use this service.',
            ),
            _buildSection(
              'License Grant',
              'Smart Wristband grants you a personal, non-exclusive, non-transferable license to use the application. You may not reproduce, duplicate, copy, or otherwise exploit our service without express written permission.',
            ),
            _buildSection(
              'User Responsibilities',
              'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to accept responsibility for all activities that occur under your account.',
            ),
            _buildSection(
              'Content',
              'You acknowledge that all content provided through the service is the property of Smart Wristband or its content suppliers. You may not reproduce, republish, or redistribute such content.',
            ),
            _buildSection(
              'Disclaimer',
              'Smart Wristband provides the service on an "as is" basis without warranty. We do not warrant that the service will be uninterrupted or error-free. Your use of the service is at your own risk.',
            ),
            _buildSection(
              'Limitation of Liability',
              'To the fullest extent permitted by law, Smart Wristband shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// Privacy Policy Page
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Information We Collect',
              'Smart Wristband collects information you provide directly such as name, email, phone number, and profile pictures. We also collect location data, communication history, and wristband connection information.',
            ),
            _buildSection(
              'How We Use Your Data',
              'Your data is used to provide and improve our services, enable real-time location sharing, facilitate messaging and attachments, save your preferences, and send you service-related updates. We do not sell your data to third parties.',
            ),
            _buildSection(
              'Location Data',
              'Your location is only visible to users within 500m of you. Location data is stored securely and updated every 10 seconds when you\'re logged in. You can control location sharing by managing app permissions.',
            ),
            _buildSection(
              'Data Security',
              'We implement industry-standard security measures to protect your personal information. All data is encrypted in transit and at rest. Firebase services provide additional security layers for authentication and database access.',
            ),
            _buildSection(
              'Third-Party Services',
              'We use Firebase (Google) for authentication, database, storage, and real-time messaging. Please review Google\'s privacy policy for their data practices.',
            ),
            _buildSection(
              'Your Rights',
              'You have the right to access, update, or delete your personal information at any time by visiting your profile. You can also request account deletion by contacting our support team.',
            ),
            _buildSection(
              'Changes to Privacy Policy',
              'Smart Wristband reserves the right to modify this privacy policy at any time. Changes will be posted in the app, and your continued use constitutes acceptance of the updated policy.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// Contact Us Page
class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Contact Us',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Have a question or feedback? We\'d love to hear from you.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            // Contact Info
            _buildContactInfo(Icons.email, 'Email', 'support@statusband.com'),
            _buildContactInfo(Icons.phone, 'Phone', '+1 (555) 123-4567'),
            _buildContactInfo(Icons.location_on, 'Address', '123 Tech Street, San Francisco, CA 94105'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.black, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
