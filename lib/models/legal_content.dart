import 'hyperlink_model.dart';

class LegalContent {
  static final HyperlinkModel termsOfService = HyperlinkModel(
    title: 'Terms of Service',
    content: '''
**Terms of Service**

Last Updated: January 15, 2026

**1. Acceptance of Terms**
By accessing or using the Smart Wristband application, you agree to be bound by these Terms of Service and all applicable laws and regulations.

**2. Description of Service**
Smart Wristband is a social connectivity platform designed to help users discover and connect with nearby individuals based on shared interests and preferences.

**3. User Accounts**
- You must be at least 18 years old to use this service
- You are responsible for maintaining the confidentiality of your account
- You agree to provide accurate and complete registration information
- You may not share your account with others

**4. User Conduct**
You agree not to:
- Harass, abuse, or harm other users
- Share inappropriate or offensive content
- Violate any applicable laws or regulations
- Attempt to gain unauthorized access to the service
- Use the service for commercial purposes without permission

**5. Relationship Status Information**
- Your relationship status is visible to other users based on your privacy settings
- You may update your relationship status at any time
- We are not responsible for how other users interpret your status

**6. Privacy and Data**
- We collect information to improve our service
- Your personal information is protected according to our Privacy Policy
- Location data is used solely for proximity-based matching

**7. Termination**
We reserve the right to terminate or suspend your account at any time for violation of these terms.

**8. Disclaimer**
The service is provided "as is" without warranties of any kind. We do not guarantee the accuracy of user information or successful connections.

**9. Limitation of Liability**
Smart Wristband shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the service.

**10. Changes to Terms**
We may modify these terms at any time. Continued use of the service constitutes acceptance of modified terms.
''',
    lastUpdated: DateTime(2026, 1, 15),
  );

  static final HyperlinkModel privacyPolicy = HyperlinkModel(
    title: 'Privacy Policy',
    content: '''
**Privacy Policy**

Last Updated: January 15, 2026

**1. Information We Collect**
We collect the following types of information:
- Account information (name, email, relationship status)
- Location data for proximity matching
- Device information and usage statistics
- Communication preferences

**2. How We Use Your Information**
We use your information to:
- Provide and improve our matching services
- Send you relevant notifications and updates
- Maintain and secure your account
- Comply with legal obligations

**3. Information Sharing**
We do not sell your personal information. We may share information with:
- Other users based on your privacy settings
- Service providers who assist in operating our platform
- Law enforcement when required by law

**4. Location Data**
- Your location is used to find nearby users
- You can disable location services at any time
- Location data is stored securely and not shared publicly

**5. Relationship Status**
- Your relationship status helps with matching algorithms
- Visibility depends on your privacy preferences
- You can change this information anytime

**6. Data Security**
We implement industry-standard security measures to protect your information including:
- Encryption of data in transit and at rest
- Regular security audits
- Access controls and monitoring

**7. Your Rights**
You have the right to:
- Access your personal information
- Request correction of inaccurate data
- Request deletion of your account
- Object to certain processing activities

**8. Data Retention**
We retain your information for as long as your account is active or as needed to comply with legal obligations.

**9. Children's Privacy**
Our service is not intended for users under 18 years of age. We do not knowingly collect information from minors.

**10. International Data Transfers**
Your information may be transferred to and processed in countries other than your own, in compliance with applicable data protection laws.

**11. Contact Us**
For privacy-related questions, contact us at privacy@smartwristband.com

**12. Changes to This Policy**
We may update this policy periodically. We will notify you of significant changes through the app or email.
''',
    lastUpdated: DateTime(2026, 1, 15),
  );
}