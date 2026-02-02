import 'package:flutter/material.dart';
import '../utils/colors.dart';

class NudgesTab extends StatefulWidget {
  const NudgesTab({super.key});

  @override
  State<NudgesTab> createState() => _NudgesTabState();
}

class _NudgesTabState extends State<NudgesTab> with TickerProviderStateMixin {
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
      body: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nudges',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
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
                    tabs: const [
                      Tab(text: 'Received'),
                      Tab(text: 'Sent'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                // Received nudges tab
                _ReceivedNudgesTab(),
                // Sent nudges tab
                _SentNudgesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedNudgesTab extends StatelessWidget {
  const _ReceivedNudgesTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Received',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4, // Sample received nudges
              itemBuilder: (context, index) {
                final users = [
                  {'name': 'Sarah Johnson', 'status': 'Online now'},
                  {'name': 'Michael Chen', 'status': 'Active 2h ago'},
                  {'name': 'Emma Wilson', 'status': 'Online now'},
                  {'name': 'David Brown', 'status': 'Active 30m ago'},
                ];

                return Card(
                  color: AppColors.surfaceVariant,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.black,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      users[index]['name']!,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      users[index]['status']!,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chat,
                            color: AppColors.black,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.favorite_border,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SentNudgesTab extends StatelessWidget {
  const _SentNudgesTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sent',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 3, // Sample sent nudges
              itemBuilder: (context, index) {
                final users = [
                  {'name': 'Alex Thompson', 'status': 'Pending response'},
                  {'name': 'Jessica Lee', 'status': 'Liked back'},
                  {'name': 'Ryan Miller', 'status': 'Pending response'},
                ];

                return Card(
                  color: AppColors.surfaceVariant,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.black,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      users[index]['name']!,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      users[index]['status']!,
                      style: TextStyle(
                        color: users[index]['status'] == 'Liked back'
                            ? AppColors.black
                            : AppColors.textSecondary,
                        fontWeight: users[index]['status'] == 'Liked back'
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: users[index]['status'] == 'Liked back'
                        ? Icon(Icons.favorite, color: Colors.red, size: 20)
                        : Icon(
                            Icons.access_time,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}