import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/core/constants/app_colors.dart';
import 'package:version/core/widgets/brand_wordmark.dart';
import 'package:version/core/widgets/goal_card.dart';
import 'package:version/core/widgets/shimmer_loading.dart';
import 'package:version/features/auth/providers/user_providers.dart';
import 'package:version/features/goals/providers/goal_providers.dart';
import 'package:version/features/home/widgets/daily_checkin_card.dart';
import 'package:version/features/home/widgets/quick_deposit_sheet.dart';
import 'package:version/features/home/widgets/weekly_chart_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const BrandWordmark(iconSize: 24, fontSize: 24),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileAsync
                        .when(
                          data: (profile) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning,',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textMid),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profile.displayName ??
                                    profile.username ??
                                    'Saver',
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              ),
                            ],
                          ),
                          loading: () => const Text('Good morning!'),
                          error: (_, __) => const Text('Good morning!'),
                        )
                        .animate()
                        .fadeIn(duration: 320.ms)
                        .slideY(begin: .15, end: 0),
                    const SizedBox(height: 18),
                    DailyCheckinCard(
                            onCheckinSuccess: () => _confettiController.play())
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 320.ms)
                        .slideY(begin: .12, end: 0),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: profileAsync.when(
                            data: (profile) => _InfoStatCard(
                              icon: Icons.monetization_on_outlined,
                              title: 'Coins',
                              value: '${profile.coins}',
                            ),
                            loading: () => const _InfoStatCard(
                              icon: Icons.monetization_on_outlined,
                              title: 'Coins',
                              value: '--',
                            ),
                            error: (_, __) => const _InfoStatCard(
                              icon: Icons.monetization_on_outlined,
                              title: 'Coins',
                              value: '--',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: profileAsync.when(
                            data: (profile) => _InfoStatCard(
                              icon: Icons.stars_rounded,
                              title: 'Level',
                              value: 'Lv ${profile.level}',
                            ),
                            loading: () => const _InfoStatCard(
                              icon: Icons.stars_rounded,
                              title: 'Level',
                              value: '--',
                            ),
                            error: (_, __) => const _InfoStatCard(
                              icon: Icons.stars_rounded,
                              title: 'Level',
                              value: '--',
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 180.ms, duration: 320.ms),
                    const SizedBox(height: 20),
                    const WeeklyChartWidget()
                        .animate()
                        .fadeIn(delay: 240.ms, duration: 320.ms)
                        .scale(
                            begin: const Offset(.98, .98),
                            end: const Offset(1, 1)),
                    const SizedBox(height: 20),
                    Text(
                      'Active Goals',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ).animate().fadeIn(delay: 280.ms, duration: 280.ms),
                    const SizedBox(height: 12),
                    goalsAsync
                        .when(
                          data: (goals) {
                            final activeGoals = goals
                                .where((goal) => goal.status.name == 'active')
                                .toList();

                            return SizedBox(
                              height: 150,
                              child: activeGoals.isEmpty
                                  ? Card(
                                      child: Center(
                                        child: Text(
                                          'No active goals yet.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: activeGoals.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        return SizedBox(
                                          width: 300,
                                          child: GoalCard(
                                              goal: activeGoals[index]),
                                        );
                                      },
                                    ),
                            );
                          },
                          loading: () => _buildHomeShimmer(),
                          error: (err, stack) =>
                              Center(child: Text('Error: $err')),
                        )
                        .animate()
                        .fadeIn(delay: 340.ms, duration: 320.ms),
                  ],
                ),
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const QuickDepositSheet(),
          );
        },
        icon: const Icon(Icons.savings),
        label: const Text('Quick Deposit'),
      ),
    );
  }

  Widget _buildHomeShimmer() {
    return const SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(child: ShimmerLoading.rectangular(width: 300, height: 150)),
          SizedBox(width: 16),
          Expanded(child: ShimmerLoading.rectangular(width: 300, height: 150)),
        ],
      ),
    );
  }
}

class _InfoStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoStatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.textMid, size: 18),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMid),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
