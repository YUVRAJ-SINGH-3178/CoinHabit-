import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:version/navigation/route_names.dart';
import 'package:version/services/supabase_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _goalTypes = [
    ('vacation', '🏝️'),
    ('emergency', '🛟'),
    ('electronics', '📱'),
    ('education', '🎓'),
    ('health', '🏥'),
    ('home', '🏠'),
    ('vehicle', '🚗'),
    ('other', '🎯'),
  ];

  String _selectedGoalType = 'other';
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSubmitting = false;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null) {
      setState(() => _notificationTime = picked);
    }
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _completeSetup() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final metadata = user.userMetadata ?? <String, dynamic>{};
      final username = (metadata['username'] as String?)?.trim();
      final displayName = (metadata['display_name'] as String?)?.trim();

      final payload = {
        'id': user.id,
        'username': username,
        'display_name': displayName,
        'notification_time': _formatTime(_notificationTime),
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        await supabase.from('users').upsert(payload);
      } catch (_) {}

      try {
        await supabase.from('profiles').upsert(payload);
      } catch (_) {}

      if (mounted) {
        context.go(RouteNames.home);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to complete setup. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tell us about you',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const Text('Primary saving goal type'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalTypes.map((entry) {
                final isSelected = _selectedGoalType == entry.$1;
                return ChoiceChip(
                  label: Text('${entry.$2} ${entry.$1}'),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedGoalType = entry.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Notification reminder time'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time),
              label: Text(_formatTime(_notificationTime)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _completeSetup,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Let's Go!"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
