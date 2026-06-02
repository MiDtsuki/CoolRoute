import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/cool_spot.dart';
import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
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
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    for (final t in _typeOptions)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? _type),
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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();
    final problem = _problem.text.trim();
    final description = _description.text.trim();
    final lat = widget.anchor.latitude;
    final lng = widget.anchor.longitude;

    if (_isHot) {
      widget.onHotZone?.call(
        HotZoneReport(
          id: 'pending-hot-$name',
          title: name,
          location: 'Reported at your location',
          category: _type,
          description: problem.isEmpty ? description : '$problem. $description',
          timeAgo: 'just now',
          verifications: 0,
          risk: HeatRisk.high,
          x: .5,
          y: .5,
          lat: lat,
          lng: lng,
        ),
      );
    } else {
      final bucket =
          _coolTypes.firstWhere((t) => t.$1 == _type).$2;
      widget.onCoolSpot?.call(
        CoolSpot(
          id: 'pending-cool-$name',
          name: name,
          type: bucket,
          category: _type,
          distance: 'Here',
          distanceMeters: 0,
          amenity: problem.isEmpty ? description : '$problem — $description',
          openStatus: 'Pending',
          verifiedBy: 0,
          source: 'You (pending)',
          lat: lat,
          lng: lng,
          x: .5,
          y: .5,
        ),
      );
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Report added to the map as pending. Thanks!'),
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
