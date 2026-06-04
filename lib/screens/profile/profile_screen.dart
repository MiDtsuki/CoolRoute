import 'package:flutter/material.dart';

import '../../dummy_data/dummy_data.dart';
import '../../models/user_profile.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../route/route_screen.dart';

/// The Profile tab. Loads the signed-in user's profile from Firestore (the doc
/// auto-creates on first read), shows their community contribution stats and
/// saved routes, and lets them edit basic info or sign out. Falls back to the
/// dummy profile if Firebase is unavailable.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfileService _service = UserProfileService();
  final FirebaseAuthService _auth = FirebaseAuthService();

  // Held directly in state (not via a swapped Future) so an edit is reflected
  // by a plain setState — no FutureBuilder re-subscription in the way.
  UserProfile _profile = DummyData.userProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _service.getCurrentUserProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  // Manual refresh — re-reads the profile (e.g. after reporting/verifying to
  // pull updated contribution counters).
  void _refresh() {
    setState(() => _loading = true);
    _load();
  }

  // Describes the underlying auth account for the "Account" row.
  String _accountLabel() {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Not signed in';
      if (user.isAnonymous) return 'Guest account';
      return user.email ?? 'Registered account';
    } catch (_) {
      return 'Prototype (offline)';
    }
  }

  Future<void> _editProfile() async {
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: _profile),
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final uid = _safeUid();
    if (uid == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cannot save — no signed-in user (uid is null).'),
        ),
      );
      return;
    }

    // Reflect the edit immediately via state. Firestore applies writes to its
    // local cache first and syncs in the background, so the UI must not depend
    // on the server-acknowledgement Future.
    setState(() {
      _profile = UserProfile(
        id: uid,
        name: result.name,
        role: result.role,
        location: result.location,
        riskProfile: result.riskProfile,
        savedRoutes: _profile.savedRoutes,
        reportCount: _profile.reportCount,
        verifiedReportCount: _profile.verifiedReportCount,
      );
    });

    try {
      await _service.updateProfile(
        uid,
        name: result.name,
        role: result.role,
        location: result.location,
        riskProfile: result.riskProfile,
      );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile saved.')),
        );
      }
    } catch (e) {
      debugPrint('VERIFY: profile write error: $e');
      if (mounted) {
        // Surface the real error so we can see what's failing.
        messenger.showSnackBar(
          SnackBar(content: Text('Saved locally, sync error: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    // AuthGate listens to auth state and rebuilds to the welcome flow on sign-out.
    try {
      await _auth.signOut();
    } catch (_) {
      // No active session — nothing to do.
    }
  }

  String? _safeUid() {
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
          child: Builder(
            builder: (context) {
              final profile = _profile;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Profile',
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(width: AppTheme.spaceSM),
                      if (_loading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loading ? null : _refresh,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  _HeaderCard(
                    profile: profile,
                    accountLabel: _accountLabel(),
                    onEdit: _editProfile,
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  _StatsRow(profile: profile),
                  const SizedBox(height: AppTheme.spaceLG),
                  _SectionTitle('Saved routes'),
                  const SizedBox(height: AppTheme.spaceSM),
                  _SavedRoutes(routes: profile.savedRoutes),
                  const SizedBox(height: AppTheme.spaceLG),
                  _SectionTitle('Account'),
                  const SizedBox(height: AppTheme.spaceSM),
                  _AccountCard(
                    profile: profile,
                    accountLabel: _accountLabel(),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.riskExtreme,
                        side: const BorderSide(color: AppTheme.riskExtreme),
                        minimumSize: const Size(64, 46),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Header card ────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.profile,
    required this.accountLabel,
    required this.onEdit,
  });

  final UserProfile profile;
  final String accountLabel;
  final VoidCallback onEdit;

  String get _initial {
    final name = profile.name.trim();
    return name.isEmpty ? '?' : name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  _initial,
                  style: tt.displayMedium?.copyWith(color: AppTheme.primaryDark),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: tt.headlineLarge),
                    const SizedBox(height: 2),
                    Text(profile.role, style: tt.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Wrap(
            spacing: AppTheme.spaceSM,
            runSpacing: AppTheme.spaceSM,
            children: [
              _InfoChip(icon: Icons.place_outlined, text: profile.location),
              _InfoChip(
                  icon: Icons.health_and_safety_outlined,
                  text: 'Heat sensitivity: ${profile.riskProfile}'),
              _InfoChip(icon: Icons.badge_outlined, text: accountLabel),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM + 2, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(text, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

// ── Stats ───────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
            value: '${profile.reportCount}',
            label: 'Reports',
            icon: Icons.local_fire_department_outlined),
        const SizedBox(width: AppTheme.spaceSM),
        _StatBox(
            value: '${profile.verifiedReportCount}',
            label: 'Verifications',
            icon: Icons.verified_outlined),
        const SizedBox(width: AppTheme.spaceSM),
        _StatBox(
            value: '${profile.savedRoutes.length}',
            label: 'Saved routes',
            icon: Icons.bookmark_outline),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(value, style: tt.displayMedium),
            const SizedBox(height: 2),
            Text(label, style: tt.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Saved routes ──────────────────────────────────────────────────────────────

class _SavedRoutes extends StatelessWidget {
  const _SavedRoutes({required this.routes});

  final List<String> routes;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Row(
          children: [
            const Icon(Icons.bookmark_border, color: AppTheme.textHint),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: Text(
                'No saved routes yet. Save a route from the Route tab to see it here.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final name in routes) ...[
          _SavedRouteCard(name: name),
          const SizedBox(height: AppTheme.spaceSM),
        ],
      ],
    );
  }
}

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
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
      child: AppCard(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Row(
          children: [
            const Icon(Icons.route, color: AppTheme.primary),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(name,
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Account card ──────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile, required this.accountLabel});

  final UserProfile profile;
  final String accountLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _AccountTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Heat sensitivity',
              value: profile.riskProfile),
          const Divider(height: 1),
          _AccountTile(
              icon: Icons.place_outlined,
              title: 'Home area',
              value: profile.location),
          const Divider(height: 1),
          _AccountTile(
              icon: Icons.badge_outlined,
              title: 'Account',
              value: accountLabel),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile(
      {required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: Theme.of(context).textTheme.labelLarge),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}

// ── Edit profile sheet ──────────────────────────────────────────────────────────

class _EditResult {
  const _EditResult({
    required this.name,
    required this.role,
    required this.location,
    required this.riskProfile,
  });

  final String name;
  final String role;
  final String location;
  final String riskProfile;
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});

  final UserProfile profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.profile.name);
  late final TextEditingController _role =
      TextEditingController(text: widget.profile.role);
  late final TextEditingController _location =
      TextEditingController(text: widget.profile.location);
  late String _riskProfile = _normalizeRisk(widget.profile.riskProfile);

  static const _riskOptions = ['Low', 'Normal', 'High'];

  static String _normalizeRisk(String value) =>
      _riskOptions.contains(value) ? value : 'Normal';

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _location.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _EditResult(
        name: _name.text.trim(),
        role: _role.text.trim(),
        location: _location.text.trim(),
        riskProfile: _riskProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMD, 10, AppTheme.spaceMD, AppTheme.spaceLG),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.borderMid,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: const SizedBox(width: 32, height: 4),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Text('Edit profile', style: tt.headlineMedium),
                const SizedBox(height: AppTheme.spaceMD),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextFormField(
                  controller: _role,
                  decoration: const InputDecoration(
                      labelText: 'Role (e.g. University Student)'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Home area'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Text('Heat sensitivity', style: tt.labelLarge),
                const SizedBox(height: AppTheme.spaceSM),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Low', label: Text('Low')),
                    ButtonSegment(value: 'Normal', label: Text('Normal')),
                    ButtonSegment(value: 'High', label: Text('High')),
                  ],
                  selected: {_riskProfile},
                  onSelectionChanged: (s) =>
                      setState(() => _riskProfile = s.first),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save changes'),
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
