import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/cool_spot.dart';
import '../../models/hot_zone_report.dart';
import '../../models/tree_pin.dart';
import '../../models/user_profile.dart';
import '../../services/cool_spot_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/report_refresh.dart';
import '../../services/report_service.dart';
import '../../services/tree_event_service.dart';
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
  UserProfile _profile = const UserProfile(
    id: '',
    name: '',
    role: '',
    location: '',
    riskProfile: 'Normal',
    savedRoutes: [],
    reportCount: 0,
    verifiedReportCount: 0,
  );
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    profileRevision.addListener(_load);
  }

  @override
  void dispose() {
    profileRevision.removeListener(_load);
    super.dispose();
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

  Future<void> _removeSavedRoute(SavedRoute route) async {
    final messenger = ScaffoldMessenger.of(context);
    final uid = _safeUid();
    if (uid == null) return;
    // Optimistically drop it from the list (match by name).
    setState(() {
      _profile = UserProfile(
        id: _profile.id,
        name: _profile.name,
        role: _profile.role,
        location: _profile.location,
        riskProfile: _profile.riskProfile,
        savedRoutes:
            _profile.savedRoutes.where((r) => r.name != route.name).toList(),
        reportCount: _profile.reportCount,
        verifiedReportCount: _profile.verifiedReportCount,
      );
    });
    messenger.showSnackBar(const SnackBar(content: Text('Route removed.')));
    try {
      await _service.removeSavedRoute(uid, route);
    } catch (e) {
      debugPrint('VERIFY: remove saved route error: $e');
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
                  _SavedRoutes(
                    routes: profile.savedRoutes,
                    onDelete: _removeSavedRoute,
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  _SectionTitle('My contributions'),
                  const SizedBox(height: AppTheme.spaceSM),
                  _MyContributions(uid: _safeUid() ?? ''),
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
  const _SavedRoutes({required this.routes, this.onDelete});

  final List<SavedRoute> routes;
  final ValueChanged<SavedRoute>? onDelete;

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
        for (final route in routes) ...[
          _SavedRouteCard(
            route: route,
            onDelete: onDelete == null ? null : () => onDelete!(route),
          ),
          const SizedBox(height: AppTheme.spaceSM),
        ],
      ],
    );
  }
}

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({required this.route, this.onDelete});

  final SavedRoute route;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Saved route')),
              body: SafeArea(
                child: RouteScreen(
                  initialSelectedRouteName: route.name,
                  initialDestination: route.hasDestination
                      ? LatLng(route.destLat!, route.destLng!)
                      : null,
                ),
              ),
            ),
          ),
        );
      },
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMD, AppTheme.spaceSM, AppTheme.spaceXS, AppTheme.spaceSM),
        child: Row(
          children: [
            const Icon(Icons.route, color: AppTheme.primary),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(route.name,
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppTheme.textHint,
                tooltip: 'Remove',
                onPressed: onDelete,
              )
            else
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

// ── My contributions ──────────────────────────────────────────────────────────

class _MyContributions extends StatelessWidget {
  const _MyContributions({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Text('Sign in to see your contributions.',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return Column(
      children: [
        _ContribSection<HotZoneReport>(
          title: 'My reports',
          icon: Icons.local_fire_department_outlined,
          loader: () => ReportService().getUserHotZoneReports(uid),
          labelOf: (r) => r.title,
          sublabelOf: (r) => r.category,
          timeOf: (r) => r.displayTimeAgo,
          canEdit: true,
          onDelete: (r) async {
            await ReportService().deleteReport(r.id);
            notifyHotZonesChanged();
          },
          onEdit: (r, ctx) => _showEditReport(ctx, r),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        _ContribSection<CoolSpot>(
          title: 'My cool spots',
          icon: Icons.ac_unit_outlined,
          loader: () => CoolSpotService().getUserCoolSpots(uid),
          labelOf: (s) => s.name,
          sublabelOf: (s) => s.displayCategory,
          timeOf: (_) => '',
          canEdit: true,
          onEdit: (s, ctx) => _showEditCoolSpot(ctx, s),
          onDelete: (s) async {
            await CoolSpotService().deleteCoolSpot(s.id);
            notifyCoolSpotsChanged();
          },
        ),
        const SizedBox(height: AppTheme.spaceSM),
        _ContribSection<TreePin>(
          title: 'My tree events',
          icon: Icons.park_outlined,
          loader: () => TreeEventService().getUserTreeEvents(uid),
          labelOf: (t) => t.title,
          sublabelOf: (t) => t.locationName,
          timeOf: (t) => t.datePlanted,
          canEdit: true,
          onEdit: (t, ctx) => _showEditTreeEvent(ctx, t),
          onDelete: (t) async {
            await TreeEventService().deleteTreeEvent(t.id);
            notifyTreeEventsChanged();
          },
        ),
      ],
    );
  }

  static Future<void> _showEditReport(
      BuildContext ctx, HotZoneReport report) async {
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditReportSheet(report: report),
    );
  }

  static Future<void> _showEditCoolSpot(BuildContext ctx, CoolSpot spot) async {
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCoolSpotSheet(spot: spot),
    );
  }

  static Future<void> _showEditTreeEvent(BuildContext ctx, TreePin event) async {
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTreeEventSheet(event: event),
    );
  }
}

// ── Generic expandable contribution section ───────────────────────────────────

class _ContribSection<T> extends StatefulWidget {
  const _ContribSection({
    required this.title,
    required this.icon,
    required this.loader,
    required this.labelOf,
    required this.sublabelOf,
    required this.timeOf,
    required this.onDelete,
    this.canEdit = false,
    this.onEdit,
  });

  final String title;
  final IconData icon;
  final Future<List<T>> Function() loader;
  final String Function(T) labelOf;
  final String Function(T) sublabelOf;
  final String Function(T) timeOf;
  final Future<void> Function(T) onDelete;
  final bool canEdit;
  final void Function(T, BuildContext)? onEdit;

  @override
  State<_ContribSection<T>> createState() => _ContribSectionState<T>();
}

class _ContribSectionState<T> extends State<_ContribSection<T>> {
  bool _expanded = false;
  bool _loading = false;
  List<T> _items = const [];
  bool _loaded = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await widget.loader();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
      _loaded = true;
    });
  }

  Future<void> _confirmDelete(T item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete "${widget.labelOf(item)}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.riskExtreme),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _items = _items.where((i) => i != item).toList());
    await widget.onDelete(item);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (_expanded && !_loaded) _load();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM + 4),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18, color: AppTheme.primary),
                  const SizedBox(width: AppTheme.spaceSM),
                  Expanded(child: Text(widget.title, style: tt.labelLarge)),
                  if (_loaded)
                    Text('${_items.length}',
                        style: tt.bodySmall!
                            .copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(width: AppTheme.spaceSM),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppTheme.textHint,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppTheme.spaceMD),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: Text('Nothing here yet.',
                    style: tt.bodySmall!
                        .copyWith(color: AppTheme.textHint)),
              )
            else
              for (final item in _items)
                _ContribRow(
                  label: widget.labelOf(item),
                  sublabel: widget.sublabelOf(item),
                  time: widget.timeOf(item),
                  canEdit: widget.canEdit,
                  onEdit: widget.onEdit == null
                      ? null
                      : () => widget.onEdit!(item, context),
                  onDelete: () => _confirmDelete(item),
                ),
          ],
        ],
      ),
    );
  }
}

// ── Single contribution row ───────────────────────────────────────────────────

class _ContribRow extends StatelessWidget {
  const _ContribRow({
    required this.label,
    required this.sublabel,
    required this.time,
    required this.onDelete,
    this.canEdit = false,
    this.onEdit,
  });

  final String label;
  final String sublabel;
  final String time;
  final VoidCallback onDelete;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMD, AppTheme.spaceSM, AppTheme.spaceXS, AppTheme.spaceSM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: tt.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (sublabel.isNotEmpty)
                  Text(sublabel,
                      style:
                          tt.bodySmall!.copyWith(color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (time.isNotEmpty)
                  Text(time,
                      style: tt.bodySmall!.copyWith(color: AppTheme.textHint)),
              ],
            ),
          ),
          if (canEdit && onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppTheme.primary,
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.textHint,
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Edit report bottom sheet ──────────────────────────────────────────────────

class _EditCoolSpotSheet extends StatefulWidget {
  const _EditCoolSpotSheet({required this.spot});
  final CoolSpot spot;

  @override
  State<_EditCoolSpotSheet> createState() => _EditCoolSpotSheetState();
}

class _EditCoolSpotSheetState extends State<_EditCoolSpotSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.spot.name);
  late final TextEditingController _category =
      TextEditingController(text: widget.spot.category);
  late final TextEditingController _amenity =
      TextEditingController(text: widget.spot.amenity);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _amenity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await CoolSpotService().updateCoolSpot(
        widget.spot.id,
        name: _name.text.trim(),
        category: _category.text.trim(),
        amenity: _amenity.text.trim(),
      );
      notifyCoolSpotsChanged();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditSheetScaffold(
      title: 'Edit cool spot',
      saving: _saving,
      onSave: _save,
      fields: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        TextFormField(
          controller: _category,
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        TextFormField(
          controller: _amenity,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'What it offers'),
        ),
      ],
    );
  }
}

class _EditTreeEventSheet extends StatefulWidget {
  const _EditTreeEventSheet({required this.event});
  final TreePin event;

  @override
  State<_EditTreeEventSheet> createState() => _EditTreeEventSheetState();
}

class _EditTreeEventSheetState extends State<_EditTreeEventSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.event.title);
  late final TextEditingController _location =
      TextEditingController(text: widget.event.locationName);
  late final TextEditingController _when =
      TextEditingController(text: widget.event.datePlanted);
  late final TextEditingController _goal =
      TextEditingController(text: widget.event.goalTrees > 0 ? '${widget.event.goalTrees}' : '');
  late final TextEditingController _description =
      TextEditingController(text: widget.event.description);
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _when.dispose();
    _goal.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await TreeEventService().updateTreeEvent(
        widget.event.id,
        title: _title.text.trim(),
        locationName: _location.text.trim(),
        when: _when.text.trim(),
        description: _description.text.trim(),
        goalTrees: int.tryParse(_goal.text.trim()) ?? 0,
      );
      notifyTreeEventsChanged();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditSheetScaffold(
      title: 'Edit tree event',
      saving: _saving,
      onSave: _save,
      fields: [
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Event title'),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        TextFormField(
          controller: _location,
          decoration: const InputDecoration(labelText: 'Location name'),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _when,
                decoration: const InputDecoration(labelText: 'When'),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: TextFormField(
                controller: _goal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Goal 🌳'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        TextFormField(
          controller: _description,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
      ],
    );
  }
}

/// Shared modal scaffold for the edit sheets (grab handle, title, fields, save).
class _EditSheetScaffold extends StatelessWidget {
  const _EditSheetScaffold({
    required this.title,
    required this.saving,
    required this.onSave,
    required this.fields,
  });

  final String title;
  final bool saving;
  final VoidCallback onSave;
  final List<Widget> fields;

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
              Text(title, style: tt.headlineMedium),
              const SizedBox(height: AppTheme.spaceMD),
              ...fields,
              const SizedBox(height: AppTheme.spaceLG),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.textOnDark),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditReportSheet extends StatefulWidget {
  const _EditReportSheet({required this.report});
  final HotZoneReport report;

  @override
  State<_EditReportSheet> createState() => _EditReportSheetState();
}

class _EditReportSheetState extends State<_EditReportSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.report.title);
  late final TextEditingController _description =
      TextEditingController(text: widget.report.description);
  late String _category = widget.report.category;
  bool _saving = false;

  static const _categories = [
    'No shade',
    'Broken water station',
    'Too hot walkway',
    'Unsafe bus stop',
    'Crowded outdoor area',
    'Other',
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ReportService().updateReport(
        widget.report.id,
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category,
      );
      notifyHotZonesChanged();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
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
              Text('Edit report', style: tt.headlineMedium),
              const SizedBox(height: AppTheme.spaceMD),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              DropdownButtonFormField<String>(
                initialValue: _categories.contains(_category) ? _category : _categories.last,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.textOnDark),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
