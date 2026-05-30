import 'package:flutter/material.dart';

import '../../dummy_data/dummy_data.dart';
import '../../models/heat_risk.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/heat_risk_badge.dart';

class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nearby = DummyData.hotZones.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 42),
                      SizedBox(height: 8),
                      Text(
                        'Large report image placeholder',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'No shade at bus stop',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const HeatRiskBadge(HeatRisk.extreme),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.place, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Main Gate Bus Stop',
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'This bus stop has no shade during afternoon hours. Many students wait here under direct sunlight.',
                      ),
                      const SizedBox(height: 16),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DetailPill(icon: Icons.category_outlined, label: 'Category', value: 'No Shade'),
                          _DetailPill(icon: Icons.schedule, label: 'Reported', value: 'Today, 1:20 PM'),
                          _DetailPill(icon: Icons.verified, label: 'Confirmed', value: '24 people'),
                          _DetailPill(icon: Icons.local_fire_department, label: 'Status', value: 'Still hot'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.local_fire_department),
                              label: const Text('Still hot'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Problem fixed'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.comment_outlined),
                          label: const Text('Add comment'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Community comments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const _CommentCard(text: 'Still very hot around 2 PM.'),
                const _CommentCard(text: 'Water station nearby is also broken.'),
                const _CommentCard(text: 'Better to use the library route.'),
                const SizedBox(height: 18),
                Text(
                  'Nearby reports in this vicinity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                for (final report in nearby) ...[
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: AppColors.extreme),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(report.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(report.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        HeatRiskBadge(report.risk),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.person, size: 18, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
