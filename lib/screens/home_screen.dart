import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'home_tab_screen.dart';
import 'maps_tab_screen.dart';
import 'messages_tab_screen.dart';
import 'nudges_tab_screen.dart';
import 'profile_tab_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _widgetOptions => [
    const HomeTabScreen(),
    const MapsTabScreen(),
    MessagesTabScreen(onNavigateToTab: _onItemTapped),
    NudgesTabScreen(onNavigateToTab: _onItemTapped),
    const ProfileTabScreen(),
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
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.divider.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Group: Home and Messages
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                    const SizedBox(width: 24),
                    _buildNavItem(2, Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
                  ],
                ),
                
                // Spacer for center position
                const SizedBox(width: 60), // Width of map button
                
                // Right Group: Nudges and Profile
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavItem(3, Icons.notifications_none, Icons.notifications, 'Nudges'),
                    const SizedBox(width: 24),
                    _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
                  ],
                ),
              ],
            ),
          ),
          
          // Center: Maps (Big Circle - Half inside, half outside)
          Positioned(
            top: -30, // Halfway above the navbar (60px height / 2)
            left: 0,
            right: 0,
            child: Center(
              child: _buildMapNavItem(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.black : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.black : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapNavItem() {
    bool isSelected = _selectedIndex == 1;
    return GestureDetector(
      onTap: () => _onItemTapped(1),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.divider,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.map_outlined,
          color: isSelected ? AppColors.white : AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}