import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String goalsBox = 'goals';
  static const String userProfileBox = 'user_profile';
  static const String appSettingsBox = 'app_settings';
  static const String offlineQueueBox = 'offline_queue';
  static const String onboardingCompleteKey = 'onboarding_complete';

  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Open boxes for caching
    await Hive.openBox(goalsBox);
    await Hive.openBox(userProfileBox);
    await Hive.openBox(appSettingsBox);
    await Hive.openBox(offlineQueueBox);
  }

  // Generic method to write data to a box
  Future<void> write(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  // Generic method to read data from a box
  dynamic read(String boxName, String key) {
    final box = Hive.box(boxName);
    return box.get(key);
  }

  bool isOnboardingComplete() {
    final settingsBox = Hive.box(appSettingsBox);
    return settingsBox.get(onboardingCompleteKey, defaultValue: false) as bool;
  }

  Future<void> setOnboardingComplete(bool value) async {
    final settingsBox = Hive.box(appSettingsBox);
    await settingsBox.put(onboardingCompleteKey, value);
  }
}
