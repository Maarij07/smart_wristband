import 'package:flutter/material.dart';
import '../utils/colors.dart';

class NudgesTabScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const NudgesTabScreen({super.key, this.onNavigateToTab});

  @override
  State<NudgesTabScreen> createState() => _NudgesTabScreenState();
}

class _NudgesTabScreenState extends State<NudgesTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sample data for demonstration
  final List<Map<String, dynamic>> _receivedNudges = [
    {
      'name': 'Sarah Chen',
      'message': 'Wants to connect with you',
      'time': '2 hours ago',
      'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop',
    },
    {
      'name': 'Mike Johnson',
      'message': 'Sent you a friendly nudge',
      'time': '1 day ago',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
    },
  ];
  
  final List<Map<String, dynamic>> _sentNudges = [
    {
      'name': 'Emma Wilson',
      'message': 'You sent a connection request',
      'time': '3 hours ago',
      'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop',
    },
  ];

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nudges',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay connected with meaningful interactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Received'),
                  Tab(text: 'Sent'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReceivedTab(),
                  _buildSentTab(),
                ],
              ),
            ),
            
            // Find People Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Maps tab (index 1)
                    if (widget.onNavigateToTab != null) {
                      widget.onNavigateToTab!(1);
                    }
                  },
                  style: AppColors.primaryButtonStyle(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map,
                        size: 20,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Find People on Map',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedTab() {
    if (_receivedNudges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox,
        title: 'No nudges received',
        subtitle: 'When someone sends you a nudge, it will appear here',
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        itemCount: _receivedNudges.length,
        itemBuilder: (context, index) {
          final nudge = _receivedNudges[index];
          return _buildNudgeItem(nudge, isReceived: true);
        },
      ),
    );
  }

  Widget _buildSentTab() {
    if (_sentNudges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send,
        title: 'No nudges sent',
        subtitle: 'Your sent nudges will appear here',
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        itemCount: _sentNudges.length,
        itemBuilder: (context, index) {
          final nudge = _sentNudges[index];
          return _buildNudgeItem(nudge, isReceived: false);
        },
      ),
    );
  }

  Widget _buildNudgeItem(Map<String, dynamic> nudge, {required bool isReceived}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(nudge['avatar']),
            child: const Icon(
              Icons.person,
              size: 24,
              color: Colors.transparent,
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nudge['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nudge['message'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Time and Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                nudge['time'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (isReceived)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Connect',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}