import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../services/nudges_service.dart';
import '../services/user_context.dart';
import '../services/firestore_messaging_service.dart';
import 'chat_screen.dart';

class NudgesTab extends StatefulWidget {
  const NudgesTab({super.key});

  @override
  State<NudgesTab> createState() => _NudgesTabState();
}

class _NudgesTabState extends State<NudgesTab> with TickerProviderStateMixin {
  late TabController _tabController;
  final NudgesService _nudgesService = NudgesService();
  final FirestoreMessagingService _messagingService = FirestoreMessagingService();

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
              children: [
                // Received nudges tab
                _ReceivedNudgesTab(
                  nudgesService: _nudgesService,
                  messagingService: _messagingService,
                ),
                // Sent nudges tab
                _SentNudgesTab(nudgesService: _nudgesService),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedNudgesTab extends StatelessWidget {
  final NudgesService nudgesService;
  final FirestoreMessagingService messagingService;

  const _ReceivedNudgesTab({
    required this.nudgesService,
    required this.messagingService,
  });

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
            child: StreamBuilder<List<NudgeItem>>(
              stream: nudgesService.getReceivedNudgesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No received nudges yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                final nudges = snapshot.data!;
                return ListView.separated(
                  itemCount: nudges.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final nudge = nudges[index];
                    final isMatched = nudge.status == 'matched';

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
                          nudge.name,
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          isMatched ? 'Liked back' : 'Sent you a nudge',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.chat,
                                color: isMatched
                                    ? AppColors.black
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: isMatched
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            contactId: nudge.userId,
                                            contactName: nudge.name,
                                            contactAvatar:
                                                _getInitials(nudge.name),
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: Icon(
                                isMatched
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isMatched
                                    ? Colors.red
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: isMatched
                                  ? null
                                  : () async {
                                      final currentUser =
                                          context.read<UserContext>().user;
                                      if (currentUser == null) {
                                        return;
                                      }

                                      await nudgesService.markMatched(
                                        otherUserId: nudge.userId,
                                        otherUserName: nudge.name,
                                        otherUserProfilePicture:
                                            nudge.profilePicture,
                                        currentUserName: currentUser.name,
                                        currentUserProfilePicture:
                                            currentUser.profilePicture,
                                      );

                                      await messagingService
                                          .createOrStartConversation(
                                        nudge.userId,
                                        nudge.name,
                                        '',
                                      );

                                      await messagingService
                                          .setNewMatchForBothUsers(
                                        userId: currentUser.id,
                                        contactId: nudge.userId,
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'U';
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }
}

class _SentNudgesTab extends StatelessWidget {
  final NudgesService nudgesService;

  const _SentNudgesTab({required this.nudgesService});

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
            child: StreamBuilder<List<NudgeItem>>(
              stream: nudgesService.getSentNudgesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No sent nudges yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                final nudges = snapshot.data!;
                return ListView.separated(
                  itemCount: nudges.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final nudge = nudges[index];
                    final isMatched = nudge.status == 'matched';

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
                          nudge.name,
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          isMatched ? 'Liked back' : 'Pending response',
                          style: TextStyle(
                            color: isMatched
                                ? AppColors.black
                                : AppColors.textSecondary,
                            fontWeight: isMatched
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                        trailing: isMatched
                            ? Icon(Icons.favorite, color: Colors.red, size: 20)
                            : Icon(
                                Icons.access_time,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}