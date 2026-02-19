import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/features/auth/repositories/user_repository.dart';
import 'package:version/services/notification_service.dart';
import 'package:version/services/offline_service.dart';
import 'package:version/services/offline_queue_service.dart';
import 'package:version/services/storage_service.dart';
import 'package:version/services/supabase_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    await StorageService.instance.init();

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('Missing SUPABASE_URL in .env');
    }
    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('Missing SUPABASE_ANON_KEY in .env');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    final userRepository = UserRepository();
    await NotificationService.instance.init(
      onTokenChanged: (token) async {
        if (supabase.auth.currentUser != null) {
          await userRepository.updatePushToken(token);
        }
      },
    );

    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        final profile = await userRepository.getUserProfile(userId);
        if (profile.notificationTime != null) {
          await NotificationService.instance
              .scheduleDailyReminderFromString(profile.notificationTime!);
        }
      } catch (_) {}
    }

    await OfflineService.instance.init();

    if (OfflineService.instance.isOnline) {
      await OfflineQueueService.instance.processQueue();
    }

    OfflineService.instance.statusStream.listen((status) async {
      if (status == NetworkStatus.online) {
        await OfflineQueueService.instance.processQueue();
      }
    });

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'App initialization failed: $error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
