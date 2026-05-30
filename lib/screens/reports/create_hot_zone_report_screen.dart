import 'package:flutter/material.dart';

import '../../models/heat_risk.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class CreateHotZoneReportScreen extends StatefulWidget {
  const CreateHotZoneReportScreen({super.key});

  @override
  State<CreateHotZoneReportScreen> createState() => _CreateHotZoneReportScreenState();
}

class _CreateHotZoneReportScreenState extends State<CreateHotZoneReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'No shade';
  HeatRisk _heatLevel = HeatRisk.high;

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
                            decoration: const InputDecoration(
                              labelText: 'Report title',
                              hintText: 'Exposed walkway near Main Gate',
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
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
                              onPressed: _submit,
                              icon: const Icon(Icons.send),
                              label: const Text('Submit Report'),
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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted. Community members can now verify it.')),
    );
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
