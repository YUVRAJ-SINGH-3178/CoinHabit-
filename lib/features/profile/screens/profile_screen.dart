import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/core/constants/colors.dart';
import 'package:version/core/widgets/shimmer_loading.dart';
import 'package:version/features/auth/providers/user_providers.dart';
import 'package:version/features/goals/providers/goal_providers.dart';
import 'package:version/features/profile/widgets/monthly_savings_chart.dart';
import 'package:version/features/profile/widgets/stat_card.dart';
import 'package:version/navigation/route_names.dart';
import 'package:version/services/notification_service.dart';
import 'package:version/services/supabase_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _githubUsername = 'YUVRAJ-SINGH-3178';
  static const _githubRepo = 'CoinHabit-';

  bool _isUploadingAvatar = false;
  bool _isUpdatingReminder = false;
  bool _isUpdatingName = false;

  void _logout() {
    supabase.auth.signOut().then((_) {
      if (mounted) {
        context.go(RouteNames.login);
      }
    });
  }

  Future<void> _uploadAvatar() async {
    if (_isUploadingAvatar) {
      return;
    }

    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 300, maxHeight: 300);
    if (imageFile == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);

    final file = File(imageFile.path);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      final avatarUrl = await userRepo.uploadAvatar(file);
      await userRepo.updateAvatarUrl(avatarUrl);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _editDisplayName(String currentName) async {
    if (_isUpdatingName) {
      return;
    }

    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          maxLength: 40,
          decoration: const InputDecoration(hintText: 'Enter display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || result == null || result.isEmpty || result == currentName) {
      return;
    }

    setState(() => _isUpdatingName = true);
    try {
      await ref.read(userRepositoryProvider).updateDisplayName(result);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update display name: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingName = false);
      }
    }
  }

  Future<void> _pickReminderTime(String? current) async {
    if (_isUpdatingReminder) {
      return;
    }

    TimeOfDay initial = const TimeOfDay(hour: 20, minute: 0);
    if (current != null && current.contains(':')) {
      final parts = current.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 20;
        final minute = int.tryParse(parts[1]) ?? 0;
        initial =
            TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
      }
    }

    final selected =
        await showTimePicker(context: context, initialTime: initial);
    if (selected == null || !mounted) {
      return;
    }

    final formatted =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';

    setState(() => _isUpdatingReminder = true);
    try {
      await ref.read(userRepositoryProvider).updateNotificationTime(formatted);
      await NotificationService.instance
          .scheduleDailyReminderFromString(formatted);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder time updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update reminder: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingReminder = false);
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _sendGithubRequest({
    required String requestType,
    required String details,
  }) async {
    final email = supabase.auth.currentUser?.email ?? 'not-provided';
    final issueTitle = '$requestType request from CoinHabit user';
    final issueBody = [
      '### Request Type',
      requestType,
      '',
      '### User',
      '- Email: $email',
      '- Timestamp: ${DateTime.now().toUtc().toIso8601String()}',
      '',
      '### Details',
      details,
      '',
      '---',
      'Requested via CoinHabit app settings.',
    ].join('\n');

    final issueUri = Uri.https(
      'github.com',
      '$_githubUsername/$_githubRepo/issues/new',
      {
        'title': issueTitle,
        'body': issueBody,
      },
    );

    final opened =
        await launchUrl(issueUri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      await _openUrl('https://github.com/$_githubUsername');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Opened GitHub profile. Please create a new request there.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opened GitHub request form.'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request account deletion'),
        content: const Text(
          'This opens GitHub with a pre-filled request to delete your account and associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _sendGithubRequest(
        requestType: 'Account and Data Deletion',
        details:
            'Please permanently delete my CoinHabit account and all linked personal/savings data.',
      );
    }
  }

  Future<void> _requestDataExport() async {
    await _sendGithubRequest(
      requestType: 'Data Export',
      details:
          'Please provide an export of all my CoinHabit account data in a standard format.',
    );
  }

  Future<void> _showFaqSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAQ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10),
                _FaqItem(
                  question: 'How are coins earned?',
                  answer:
                      'Coins are earned from check-ins, deposits, and goal milestones.',
                ),
                _FaqItem(
                  question: 'Can I use the app offline?',
                  answer:
                      'Yes. Actions are queued offline and synced when your connection is restored.',
                ),
                _FaqItem(
                  question: 'How do I change reminders?',
                  answer:
                      'Use Settings > Daily Reminder in the profile screen to update your time.',
                ),
                _FaqItem(
                  question: 'How do I delete my account and data?',
                  answer:
                      'Use Settings > Delete Account & Data Request to open a pre-filled GitHub request.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final completedGoalsAsync = ref.watch(completedGoalsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (user) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _uploadAvatar,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.cardGray,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : user.avatarUrl == null
                                    ? const Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: AppColors.textLight,
                                      )
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                user.displayName ??
                                    user.username ??
                                    'Anonymous',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: _isUpdatingName
                                  ? null
                                  : () => _editDisplayName(
                                        user.displayName ??
                                            user.username ??
                                            'Anonymous',
                                      ),
                              icon: _isUpdatingName
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.edit, size: 18),
                            ),
                          ],
                        ),
                        Text(
                          supabase.auth.currentUser!.email!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text('Level ${user.level}'),
                          backgroundColor:
                              AppColors.primaryGold.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Daily Reminder'),
                    subtitle: Text(
                      user.notificationTime == null
                          ? 'Not set'
                          : DateFormat.jm().format(
                              DateTime(
                                2000,
                                1,
                                1,
                                int.parse(user.notificationTime!.split(':')[0]),
                                int.parse(user.notificationTime!.split(':')[1]),
                              ),
                            ),
                    ),
                    trailing: _isUpdatingReminder
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isUpdatingReminder
                        ? null
                        : () => _pickReminderTime(user.notificationTime),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatCard(
                        title: 'Longest Streak',
                        value: user.streakLongest.toString(),
                        icon: Icons.local_fire_department),
                    StatCard(
                      title: 'Goals Completed',
                      value: completedGoalsAsync.when(
                        data: (value) => value.toString(),
                        loading: () => '...',
                        error: (_, __) => '--',
                      ),
                      icon: Icons.flag,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Savings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        MonthlySavingsChart(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.help_outline_rounded),
                        title: const Text('FAQ'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showFaqSheet,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.support_agent_rounded),
                        title: const Text('Support (GitHub)'),
                        subtitle: const Text('@YUVRAJ-SINGH-3178/CoinHabit-'),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () => _openUrl(
                          'https://github.com/$_githubUsername/$_githubRepo',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: const Text('Request My Data Export'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _requestDataExport,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded,
                            color: AppColors.dangerRed),
                        title: const Text(
                          'Delete Account & Data Request',
                          style: TextStyle(color: AppColors.dangerRed),
                        ),
                        subtitle:
                            const Text('Sends a request via GitHub issue'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _confirmDeleteRequest,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => _buildProfileShimmer(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileShimmer() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShimmerLoading.circular(size: 100),
          SizedBox(height: 12),
          ShimmerLoading.rectangular(width: 200, height: 24),
          SizedBox(height: 8),
          ShimmerLoading.rectangular(width: 150, height: 16),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ShimmerLoading.rectangular(width: 120, height: 100),
              ShimmerLoading.rectangular(width: 120, height: 100),
            ],
          ),
          SizedBox(height: 24),
          ShimmerLoading.rectangular(width: double.infinity, height: 200),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 10),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(answer),
        ),
      ],
    );
  }
}
