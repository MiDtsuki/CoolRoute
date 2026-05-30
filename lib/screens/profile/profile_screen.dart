import 'package:flutter/material.dart';

import '../route/route_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(Icons.person, color: AppColors.primaryDark, size: 38),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nicha',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            const Text('University Student', style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _ProfileChip(icon: Icons.place, text: 'Bangkok, Thailand'),
                                _ProfileChip(icon: Icons.health_and_safety, text: 'Risk profile: Normal'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 2 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: MediaQuery.sizeOf(context).width > 650 ? 3.3 : 4.2,
                  children: const [
                    _ProfileActionCard(icon: Icons.bookmark, title: 'Saved Routes', value: '3 routes'),
                    _ProfileActionCard(icon: Icons.local_fire_department, title: 'My Hot Zone Reports', value: '5 reports'),
                    _ProfileActionCard(icon: Icons.verified, title: 'My Verified Reports', value: '18 verifications'),
                    _ProfileActionCard(icon: Icons.tune, title: 'Heat Safety Preferences', value: 'Normal sensitivity'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Saved routes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const _SavedRouteCard(name: 'Dormitory to Library', meta: 'Cooler route • 11 min'),
                const _SavedRouteCard(name: 'Main Gate to Cafeteria', meta: 'Avoids hot zones • 8 min'),
                const _SavedRouteCard(name: 'Library to Bus Stop', meta: 'Shaded walkway • 7 min'),
                const SizedBox(height: 18),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(icon: Icons.health_and_safety, title: 'Risk profile', value: 'Normal'),
                      Divider(height: 1),
                      _SettingsTile(icon: Icons.notifications_outlined, title: 'Notification preference', value: 'Heat alerts on'),
                      Divider(height: 1),
                      _SettingsTile(icon: Icons.alt_route, title: 'Preferred route type', value: 'Balanced safety'),
                      Divider(height: 1),
                      _SettingsTile(icon: Icons.satellite_alt, title: 'Data source settings', value: 'NASA + Weather'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({required this.name, required this.meta});

  final String name;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Saved route')),
              body: SafeArea(child: RouteScreen(initialSelectedRouteName: name)),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.route, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(meta, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
