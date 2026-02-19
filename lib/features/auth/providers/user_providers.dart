import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/features/auth/repositories/user_repository.dart';
import 'package:version/models/user_profile.dart';
import 'package:version/services/supabase_service.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

final userProfileProvider = FutureProvider<UserProfile>((ref) {
  final userId = supabase.auth.currentUser!.id;
  return ref.watch(userRepositoryProvider).getUserProfile(userId);
});
