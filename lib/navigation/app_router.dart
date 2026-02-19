import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:version/features/auth/screens/forgot_password_screen.dart';
import 'package:version/features/auth/screens/login_screen.dart';
import 'package:version/features/auth/screens/onboarding_screen.dart';
import 'package:version/features/auth/screens/profile_setup_screen.dart';
import 'package:version/features/auth/screens/signup_screen.dart';
import 'package:version/features/auth/screens/splash_screen.dart';
import 'package:version/features/goals/screens/add_edit_goal_screen.dart';
import 'package:version/features/goals/screens/goal_detail_screen.dart';
import 'package:version/features/goals/screens/goals_screen.dart';
import 'package:version/features/home/screens/home_screen.dart';
import 'package:version/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:version/features/profile/screens/profile_screen.dart';
import 'package:version/features/rewards/screens/rewards_screen.dart';
import 'package:version/navigation/route_names.dart';
import 'package:version/services/storage_service.dart';
import 'package:version/services/supabase_service.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final _routerRefresh =
      GoRouterRefreshStream(supabase.auth.onAuthStateChange);

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: _routerRefresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final hasSession = supabase.auth.currentSession != null;
      final hasCompletedOnboarding =
          StorageService.instance.isOnboardingComplete();

      final isSplash = location == RouteNames.splash;
      final isOnboarding = location == RouteNames.onboarding;
      final isLogin = location == RouteNames.login;
      final isSignup = location == RouteNames.signup;
      final isForgotPassword = location == RouteNames.forgotPassword;
      final isPublicAuthRoute = isSplash || isOnboarding || isLogin || isSignup;

      if (!hasCompletedOnboarding && !isSplash && !isOnboarding) {
        return RouteNames.onboarding;
      }

      if (hasCompletedOnboarding && isOnboarding) {
        return hasSession ? RouteNames.home : RouteNames.login;
      }

      if (!hasSession && !isPublicAuthRoute && !isForgotPassword) {
        return RouteNames.login;
      }

      if (hasSession && (isLogin || isSignup)) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const OnboardingScreen()),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.signup,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const SignupScreen()),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.profileSetup,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const ProfileSetupScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.addGoal,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const AddEditGoalScreen()),
      ),
      GoRoute(
        path: '${RouteNames.goalDetails}/:id',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          GoalDetailScreen(goalId: state.pathParameters['id']!),
        ),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => _buildPageWithTransition(
          context,
          state,
          Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _calculateSelectedIndex(state.uri.toString()),
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.flag_outlined),
                  selectedIcon: Icon(Icons.flag_rounded),
                  label: 'Goals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events),
                  label: 'Rewards',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  selectedIcon: Icon(Icons.leaderboard),
                  label: 'Leaderboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: RouteNames.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: RouteNames.goals,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GoalsScreen()),
          ),
          GoRoute(
            path: RouteNames.rewards,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RewardsScreen()),
          ),
          GoRoute(
            path: RouteNames.leaderboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LeaderboardScreen()),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );

  static CustomTransitionPage _buildPageWithTransition<T>(
      BuildContext context, GoRouterState state, Widget child) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  static int _calculateSelectedIndex(String location) {
    if (location.startsWith(RouteNames.home)) {
      return 0;
    } else if (location.startsWith(RouteNames.goals)) {
      return 1;
    } else if (location.startsWith(RouteNames.rewards)) {
      return 2;
    } else if (location.startsWith(RouteNames.leaderboard)) {
      return 3;
    } else if (location.startsWith(RouteNames.profile)) {
      return 4;
    }
    return 0;
  }

  static void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        context.go(RouteNames.goals);
        break;
      case 2:
        context.go(RouteNames.rewards);
        break;
      case 3:
        context.go(RouteNames.leaderboard);
        break;
      case 4:
        context.go(RouteNames.profile);
        break;
    }
  }
}
