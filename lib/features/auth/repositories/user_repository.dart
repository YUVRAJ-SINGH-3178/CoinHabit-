import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version/models/user_profile.dart';
import 'package:version/services/supabase_service.dart';

class UserRepository {
  Future<UserProfile> getUserProfile(String userId) async {
    final response =
        await supabase.from('profiles').select().eq('id', userId).single();
    return UserProfile.fromJson(response);
  }

  Future<bool> processCheckIn() async {
    try {
      await supabase.rpc('process_checkin');
      return true;
    } catch (_) {
      try {
        await supabase.functions.invoke('process-checkin');
        return true;
      } catch (_) {}

      final userId = supabase.auth.currentUser!.id;
      final profile = await supabase
          .from('profiles')
          .select('coins, streak_current, streak_longest, last_checkin_date')
          .eq('id', userId)
          .single();

      final now = DateTime.now();
      final lastCheckinRaw = profile['last_checkin_date'] as String?;
      final lastCheckin =
          lastCheckinRaw == null ? null : DateTime.tryParse(lastCheckinRaw);

      final hasCheckedInToday = lastCheckin != null &&
          lastCheckin.year == now.year &&
          lastCheckin.month == now.month &&
          lastCheckin.day == now.day;

      if (hasCheckedInToday) {
        return false;
      }

      final wasYesterday = lastCheckin != null &&
          lastCheckin.year == now.subtract(const Duration(days: 1)).year &&
          lastCheckin.month == now.subtract(const Duration(days: 1)).month &&
          lastCheckin.day == now.subtract(const Duration(days: 1)).day;

      final currentStreak = (profile['streak_current'] as num?)?.toInt() ?? 0;
      final longestStreak = (profile['streak_longest'] as num?)?.toInt() ?? 0;
      final currentCoins = (profile['coins'] as num?)?.toInt() ?? 0;

      final nextStreak = wasYesterday ? currentStreak + 1 : 1;
      final nextLongest =
          nextStreak > longestStreak ? nextStreak : longestStreak;

      await supabase.from('profiles').update({
        'coins': currentCoins + 10,
        'streak_current': nextStreak,
        'streak_longest': nextLongest,
        'last_checkin_date': now.toIso8601String(),
      }).eq('id', userId);

      return true;
    }
  }

  Future<String> uploadAvatar(File image) async {
    final userId = supabase.auth.currentUser!.id;
    final fileExtension = image.path.split('.').last;
    final fileName = '$userId/avatar.$fileExtension';

    await supabase.storage.from('avatars').upload(
          fileName,
          image,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return supabase.storage.from('avatars').getPublicUrl(fileName);
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('profiles')
        .update({'avatar_url': avatarUrl}).eq('id', userId);
  }

  Future<void> updateNotificationTime(String? time) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('profiles')
        .update({'notification_time': time}).eq('id', userId);
  }

  Future<void> updateDisplayName(String displayName) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('profiles')
        .update({'display_name': displayName}).eq('id', userId);
  }

  Future<void> updatePushToken(String token) async {
    final userId = supabase.auth.currentUser!.id;
    try {
      await supabase.from('profiles').update({
        'fcm_token': token,
        'fcm_token_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } on PostgrestException {
      // Column may not exist yet in some environments; ignore gracefully.
    }
  }
}
