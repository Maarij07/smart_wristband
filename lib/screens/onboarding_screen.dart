import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Set Your Status',
      'subtitle': 'Set your relationship status and let others know you\'re available',
      'imageUrl': 'assets/images/onboard_status.png', // To be replaced with actual vector image
    },
    {
      'title': 'Meet Like-Minded People',
      'subtitle': 'Discover and connect with singles in your area',
      'imageUrl': 'assets/images/onboard_meet.png', // To be replaced with actual vector image
    },
    {
      'title': 'Stay Connected',
      'subtitle': 'Get notified when compatible matches are nearby',
      'imageUrl': 'assets/images/onboard_connect.png', // To be replaced with actual vector image
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
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
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              // Page view
              Expanded(
                flex: 2,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return _buildPage(index);
                  },
                ),
              ),

              // Indicator dots
              Container(
                margin: const EdgeInsets.only(top: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? AppColors.black 
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Continue button
              Container(
                margin: const EdgeInsets.only(top: 32),
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    }
                  },
                  style: AppColors.primaryButtonStyle(),
                  child: Text(
                    _currentPage == _onboardingData.length - 1 
                        ? 'Get Started' 
                        : 'Continue',
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
    );
  }

  Widget _buildPage(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image placeholder
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.watch,
            size: 80,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 48),

        // Title
        Text(
          _onboardingData[index]['title']!,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Subtitle
        Text(
          _onboardingData[index]['subtitle']!,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}