import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(24),
                      radius: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _BrandMark(),
                          const Spacer(),
                          Text(
                            'CoolRoute',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textMain,
                                ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Heat-safe navigation for students, commuters, and communities in hotter cities.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          const Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _FeaturePill(icon: Icons.alt_route, text: 'Safer routes'),
                              _FeaturePill(icon: Icons.local_fire_department, text: 'Hot reports'),
                              _FeaturePill(icon: Icons.ac_unit, text: 'Cool spots'),
                              _FeaturePill(icon: Icons.satellite_alt, text: 'NASA data'),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text('Get started'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.route, color: AppColors.primaryDark, size: 34),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 7),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
