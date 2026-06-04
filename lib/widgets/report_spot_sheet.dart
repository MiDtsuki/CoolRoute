import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/cool_spot.dart';
import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
import '../services/cool_spot_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/report_refresh.dart';
import '../services/report_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';

enum ReportSpotMode { coolSpot, hotZone }

/// A community report form. On submit it builds a pending/unverified entity and
/// hands it back so the map can drop the pin immediately. The pin is anchored
/// at [anchor] (the user's current location).
class ReportSpotSheet extends StatefulWidget {
  const ReportSpotSheet({
    super.key,
    required this.mode,
    required this.anchor,
    this.onCoolSpot,
    this.onHotZone,
  });

  final ReportSpotMode mode;
  final LatLng anchor;
  final ValueChanged<CoolSpot>? onCoolSpot;
  final ValueChanged<HotZoneReport>? onHotZone;

  @override
  State<ReportSpotSheet> createState() => _ReportSpotSheetState();
}

class _ReportSpotSheetState extends State<ReportSpotSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _problem = TextEditingController();
  final _description = TextEditingController();
  late String _type;
  bool _photoAttached = false;

  bool get _isHot => widget.mode == ReportSpotMode.hotZone;

  // (label shown, marker bucket) — cool spots map to a theme category.
  static const _coolTypes = <(String, String)>[
    ('Water refill station', 'Water'),
    ('Shade / tree area', 'Shade'),
    ('Park', 'Shade'),
    ('Air-conditioned place', 'Air-conditioned'),
    ('Convenience store', 'Air-conditioned'),
    ('Library', 'Air-conditioned'),
    ('Shopping mall', 'Air-conditioned'),
  ];

  static const _hotTypes = <String>[
    'No shade',
    'Broken water station',
    'Too hot walkway',
    'Unsafe bus stop',
    'Crowded outdoor area',
  ];

  List<String> get _typeOptions =>
      _isHot ? _hotTypes : _coolTypes.map((t) => t.$1).toList();

  @override
  void initState() {
    super.initState();
    _type = _typeOptions.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _problem.dispose();
    _description.dispose();
    super.dispose();
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
            AppTheme.spaceMD,
            10,
            AppTheme.spaceMD,
            AppTheme.spaceLG,
          ),
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
                Text(_isHot ? 'Report a Hot Zone' : 'Suggest a Cool Spot',
                    style: tt.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Your report is added to the map as pending until others verify it.',
                  style: tt.bodySmall!.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Place name'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                // A tap-to-open scrollable picker rather than a dropdown menu:
                // dropdown overlays leak mouse-wheel scroll to the Google Map
                // platform view on web (it zooms instead of scrolling the list).
                InkWell(
                  onTap: _pickType,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Type'),
                    child: Row(
                      children: [
                        Expanded(child: Text(_type, style: tt.bodyMedium)),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.textHint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextFormField(
                  controller: _problem,
                  decoration: InputDecoration(
                    labelText: _isHot
                        ? 'Problem (e.g. no shade, broken water)'
                        : 'Problem / note (optional)',
                  ),
                  validator: _isHot ? _required : null,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                _PhotoUpload(
                  attached: _photoAttached,
                  onTap: () => setState(() => _photoAttached = !_photoAttached),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit report'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _name.text.trim();
    final problem = _problem.text.trim();
    final description = _description.text.trim();
    final combined = problem.isEmpty ? description : '$problem. $description';
    final lat = widget.anchor.latitude;
    final lng = widget.anchor.longitude;
    final uid = _currentUid();

    if (_isHot) {
      // Optimistic pin (temp id) so it shows immediately, then persist.
      widget.onHotZone?.call(
        HotZoneReport(
          id: 'pending-hot-$name',
          title: name,
          location: 'Reported at your location',
          category: _type,
          description: combined,
          timeAgo: 'just now',
          verifications: 1,
          risk: HeatRisk.high,
          x: .5,
          y: .5,
          lat: lat,
          lng: lng,
        ),
      );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Hot zone reported. Saving…')),
      );
      try {
        await ReportService().submitHotZoneReport(
          title: name,
          location: 'Reported at your location',
          category: _type,
          description: combined,
          risk: HeatRisk.high,
          x: .5,
          y: .5,
          lat: lat,
          lng: lng,
          userId: uid,
        );
        if (uid != null) {
          await UserProfileService().incrementReportCount(uid);
        }
        // Tell live screens (Map, Home) to reload so the new report appears
        // with its real Firestore id.
        notifyHotZonesChanged();
      } catch (e) {
        // Durable in Firestore's local cache; will sync. Logged for diagnosis.
        debugPrint('VERIFY: hot zone persist error: $e');
      }
      return;
    }

    // Cool spot: optimistic pin, then persist to Firestore.
    final bucket = _coolTypes.firstWhere((t) => t.$1 == _type).$2;
    final amenity = problem.isEmpty ? description : '$problem — $description';
    widget.onCoolSpot?.call(
      CoolSpot(
        id: 'pending-cool-$name',
        name: name,
        type: bucket,
        category: _type,
        distance: 'Here',
        distanceMeters: 0,
        amenity: amenity,
        openStatus: 'Open',
        verifiedBy: 1,
        source: 'community',
        lat: lat,
        lng: lng,
        x: .5,
        y: .5,
      ),
    );
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Cool spot suggested. Saving…')),
    );
    try {
      await CoolSpotService().submitCoolSpot(
        name: name,
        type: bucket,
        category: _type,
        amenity: amenity,
        openStatus: 'Open',
        x: .5,
        y: .5,
        lat: lat,
        lng: lng,
        userId: uid,
      );
      notifyCoolSpotsChanged();
    } catch (e) {
      debugPrint('VERIFY: cool spot persist error: $e');
    }
  }

  String? _currentUid() {
    try {
      return FirebaseAuthService().currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickType() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TypePickerSheet(options: _typeOptions, selected: _type),
    );
    if (picked != null && mounted) setState(() => _type = picked);
  }
}

// A scrollable, modal type picker. A full-surface modal sheet reliably captures
// mouse-wheel scrolling on web (unlike a dropdown overlay over the map).
class _TypePickerSheet extends StatelessWidget {
  const _TypePickerSheet({required this.options, required this.selected});

  final List<String> options;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 32,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.borderMid,
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusPill)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMD, 0, AppTheme.spaceMD, AppTheme.spaceSM),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select type', style: tt.labelLarge),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final option = options[i];
                    final isSelected = option == selected;
                    return ListTile(
                      title: Text(option, style: tt.bodyLarge),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppTheme.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoUpload extends StatelessWidget {
  const _PhotoUpload({required this.attached, required this.onTap});

  final bool attached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: attached ? AppTheme.primaryLight : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: attached ? AppTheme.primary : AppTheme.borderLight,
            width: .5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              attached ? Icons.check_circle : Icons.add_a_photo_outlined,
              color: attached ? AppTheme.primary : AppTheme.textHint,
              size: 22,
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(
                attached ? 'Photo attached' : 'Add a photo (optional)',
                style: tt.bodyMedium!.copyWith(
                  color: attached ? AppTheme.primaryDark : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
