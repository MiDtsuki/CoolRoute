import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'location_pin_picker.dart';

class SuggestCoolSpotSheet extends StatefulWidget {
  const SuggestCoolSpotSheet({super.key});

  @override
  State<SuggestCoolSpotSheet> createState() => _SuggestCoolSpotSheetState();
}

class _SuggestCoolSpotSheetState extends State<SuggestCoolSpotSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Shade';
  Offset _pin = const Offset(.52, .48);

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Suggest a Cool Spot',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Spot name'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'Shade', child: Text('Shade')),
                    DropdownMenuItem(value: 'Water', child: Text('Water')),
                    DropdownMenuItem(
                      value: 'Air-conditioned',
                      child: Text('Air-conditioned'),
                    ),
                    DropdownMenuItem(
                      value: 'Indoor cooling',
                      child: Text('Indoor cooling'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextFormField(
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Location note'),
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                LocationPinPicker(
                  label: 'Pin exact cool spot location',
                  pinColor: _type == 'Water'
                      ? AppTheme.markerBlue
                      : AppTheme.markerGreen,
                  pinIcon: _type == 'Water'
                      ? Icons.water_drop_outlined
                      : Icons.ac_unit,
                  onChanged: (pin) => _pin = pin,
                ),
                const SizedBox(height: AppTheme.spaceMD),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit'),
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
    final placedPin = _pin;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Thanks for your suggestion! Pin saved near ${placedPin.dx.toStringAsFixed(2)}, ${placedPin.dy.toStringAsFixed(2)}.',
        ),
      ),
    );
  }
}
