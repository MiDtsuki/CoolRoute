import 'package:flutter/material.dart';

import '../../models/heat_risk.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/report_refresh.dart';
import '../../services/report_service.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class CreateHotZoneReportScreen extends StatefulWidget {
  const CreateHotZoneReportScreen({super.key});

  @override
  State<CreateHotZoneReportScreen> createState() => _CreateHotZoneReportScreenState();
}

class _CreateHotZoneReportScreenState extends State<CreateHotZoneReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  String _category = 'No shade';
  HeatRisk _heatLevel = HeatRisk.high;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report hot zone')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Hot Zone Report',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Help others avoid risky heat exposure by sharing what you see.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _title,
                            decoration: const InputDecoration(
                              labelText: 'Report title',
                              hintText: 'Exposed walkway near Main Gate',
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _location,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              hintText: 'Bangkok, Thailand',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'No shade', child: Text('No shade')),
                              DropdownMenuItem(value: 'Broken water station', child: Text('Broken water station')),
                              DropdownMenuItem(value: 'Too hot walkway', child: Text('Too hot walkway')),
                              DropdownMenuItem(value: 'Unsafe bus stop', child: Text('Unsafe bus stop')),
                              DropdownMenuItem(value: 'Crowded outdoor area', child: Text('Crowded outdoor area')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (value) => setState(() => _category = value ?? _category),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Heat level',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<HeatRisk>(
                            segments: const [
                              ButtonSegment(value: HeatRisk.low, label: Text('Low')),
                              ButtonSegment(value: HeatRisk.medium, label: Text('Medium')),
                              ButtonSegment(value: HeatRisk.high, label: Text('High')),
                              ButtonSegment(value: HeatRisk.extreme, label: Text('Extreme')),
                            ],
                            selected: {_heatLevel},
                            onSelectionChanged: (value) => setState(() => _heatLevel = value.first),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _description,
                            minLines: 4,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Describe the heat issue and when it is worst.',
                              alignLabelWithHint: true,
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          _ImageUploadPlaceholder(heatLevel: _heatLevel),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppTheme.textOnDark),
                                    )
                                  : const Icon(Icons.send),
                              label: Text(_submitting ? 'Submitting…' : 'Submit Report'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);

    final uid = _currentUid();
    try {
      await ReportService().submitHotZoneReport(
        title: _title.text.trim(),
        location: _location.text.trim(),
        category: _category,
        description: _description.text.trim(),
        risk: _heatLevel,
        x: 0.5,
        y: 0.5,
        userId: uid,
      );
      if (uid != null) {
        await UserProfileService().incrementReportCount(uid);
        notifyProfileChanged();
      }
      // Tell Map + Home to reload so this report shows up there too.
      notifyHotZonesChanged();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Community members can now verify it.'),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Saved locally, sync issue: $e')),
        );
      }
    }
  }

  String? _currentUid() {
    try {
      return FirebaseAuthService().currentUser?.uid;
    } catch (_) {
      return null;
    }
  }
}

class _ImageUploadPlaceholder extends StatelessWidget {
  const _ImageUploadPlaceholder({required this.heatLevel});

  final HeatRisk heatLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _riskColor.withValues(alpha: .12),
            child: Icon(Icons.add_photo_alternate_outlined, color: _riskColor),
          ),
          const SizedBox(height: 10),
          const Text('Add report photo', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
            'Image upload placeholder for prototype',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color get _riskColor => switch (heatLevel) {
        HeatRisk.low => AppColors.safe,
        HeatRisk.medium => AppColors.moderate,
        HeatRisk.high => AppColors.high,
        HeatRisk.extreme => AppColors.extreme,
      };
}
