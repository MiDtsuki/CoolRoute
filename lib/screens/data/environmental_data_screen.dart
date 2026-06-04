import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/environmental_layer.dart';
import '../../services/environmental_data_service.dart';
import '../../services/nasa_gibs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gibs_tile_map.dart';
import '../../widgets/layer_chip_bar.dart';

class EnvironmentalDataScreen extends StatefulWidget {
  const EnvironmentalDataScreen({super.key});

  @override
  State<EnvironmentalDataScreen> createState() => _EnvironmentalDataScreenState();
}

class _EnvironmentalDataScreenState extends State<EnvironmentalDataScreen> {
  final _service = EnvironmentalDataService();
  final _gibs = const NasaGibsService();
  late final Future<EnvironmentalDataSnapshot> _snapshot = _service.load();

  int _selected = 0;
  late DateTime _selectedDate = _defaultGibsDate();
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  static DateTime _defaultGibsDate() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: 3));
  }

  void _selectLayer(int i) => setState(() => _selected = i);
  void _selectDate(DateTime d) => setState(() => _selectedDate = d);

  Future<void> _pickCustomDate() async {
    final today = DateTime.now().toUtc();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.utc(2000, 2, 24),
      lastDate: DateTime.utc(today.year, today.month, today.day),
      helpText: 'Pick a NASA GIBS date',
    );
    if (picked != null) _selectDate(DateTime.utc(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.bgDark,
      child: FutureBuilder<EnvironmentalDataSnapshot>(
        future: _snapshot,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          return _Layout(
            layers: snapshot.data!.layers,
            gibs: _gibs,
            selectedIndex: _selected,
            onSelectLayer: _selectLayer,
            now: _now,
            selectedDate: _selectedDate,
            onSelectDate: _selectDate,
            onPickCustomDate: _pickCustomDate,
          );
        },
      ),
    );
  }
}

// ── Layout ────────────────────────────────────────────────────────────────────

class _Layout extends StatelessWidget {
  const _Layout({
    required this.layers,
    required this.gibs,
    required this.selectedIndex,
    required this.onSelectLayer,
    required this.now,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onPickCustomDate,
  });

  final List<EnvironmentalLayer> layers;
  final NasaGibsService gibs;
  final int selectedIndex;
  final ValueChanged<int> onSelectLayer;
  final DateTime now;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPickCustomDate;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;
    final layer = layers[selectedIndex];
    final labels = layers.map((l) => l.name).toList(growable: false);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(now: now),
        _DatePresetBar(
          selectedDate: selectedDate,
          onSelect: onSelectDate,
          onPickCustom: onPickCustomDate,
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Expanded(
          child: _VizPanel(
            layer: layer,
            labels: labels,
            selectedIndex: selectedIndex,
            onSelect: onSelectLayer,
            gibs: gibs,
            date: selectedDate,
          ),
        ),
        _InfoPanel(layer: layer, date: selectedDate),
      ],
    );

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LayerSidebar(
                  layers: layers,
                  selectedIndex: selectedIndex,
                  onSelect: onSelectLayer),
              Expanded(child: body),
            ],
          )
        : body;
  }
}

// ── Header (title + live now) ─────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  static final _liveFmt = DateFormat('MMM d, y · h:mm a');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environmental data',
            style: tt.headlineLarge!.copyWith(color: AppTheme.textOnDark),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.fiber_manual_record,
                  size: 8, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'Live · ${_liveFmt.format(now)}',
                style: tt.bodySmall!.copyWith(color: AppTheme.textOnDarkDim),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Date preset bar ───────────────────────────────────────────────────────────

class _DatePresetBar extends StatelessWidget {
  const _DatePresetBar({
    required this.selectedDate,
    required this.onSelect,
    required this.onPickCustom,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPickCustom;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final presets = <(String, DateTime)>[
      ('Today', today),
      ('1d', today.subtract(const Duration(days: 1))),
      ('3d', today.subtract(const Duration(days: 3))),
      ('1w', today.subtract(const Duration(days: 7))),
      ('1mo', today.subtract(const Duration(days: 30))),
    ];
    final selectedD = DateTime.utc(
        selectedDate.year, selectedDate.month, selectedDate.day);
    final matchesPreset = presets.any((p) => _sameDay(p.$2, selectedD));

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
        itemCount: presets.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.spaceXS + 2),
        itemBuilder: (_, i) {
          if (i < presets.length) {
            final (label, date) = presets[i];
            return _DateChip(
              label: label,
              selected: _sameDay(date, selectedD),
              onTap: () => onSelect(date),
            );
          }
          return _DateChip(
            label: 'Custom',
            icon: Icons.calendar_today,
            selected: !matchesPreset,
            onTap: onPickCustom,
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final fg = selected ? AppTheme.textOnDark : AppTheme.textOnDarkMid;
    return Material(
      color: selected ? AppTheme.primary : AppTheme.bgDarkAlt,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMD, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: tt.labelSmall!
                    .copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Viz panel ─────────────────────────────────────────────────────────────────

class _VizPanel extends StatelessWidget {
  const _VizPanel({
    required this.layer,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
    required this.gibs,
    required this.date,
  });

  final EnvironmentalLayer layer;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final NasaGibsService gibs;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final fallback = _HeatmapBackdrop(palette: layer.palette);
    final gibsId = layer.gibsLayerId;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (gibsId == null)
          fallback
        else
          GibsTileMap(
            layer: layer,
            date: date,
            gibs: gibs,
            fallback: fallback,
          ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x66000000)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayerChipBar(
                labels: labels,
                selectedIndex: selectedIndex,
                onSelect: onSelect,
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: AppTheme.spaceMD,
                    right: AppTheme.spaceMD,
                    top: AppTheme.spaceXS,
                    bottom: AppTheme.spaceSM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Drag & pinch to move',
                      style: tt.labelSmall!
                          .copyWith(color: AppTheme.textOnDarkDim),
                    ),
                    Text(
                      layer.source,
                      style: tt.labelSmall!
                          .copyWith(color: AppTheme.textOnDarkDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info panel ────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.layer, required this.date});

  final EnvironmentalLayer layer;
  final DateTime date;

  static final _dateFmt = DateFormat('MMM d, y');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppTheme.bgDarkAlt,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.spaceMD, AppTheme.spaceMD,
            AppTheme.spaceMD, AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(layer.name,
                      style: tt.headlineMedium!
                          .copyWith(color: AppTheme.primary)),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(layer.value,
                        style: tt.headlineSmall!
                            .copyWith(color: AppTheme.textOnDark)),
                    Text('typical',
                        style: tt.labelSmall!
                            .copyWith(color: AppTheme.textOnDarkDim)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(layer.status,
                style: tt.bodyMedium!.copyWith(color: AppTheme.textOnDarkMid)),
            const SizedBox(height: AppTheme.spaceSM),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppTheme.textOnDarkDim),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    layer.blurb,
                    style: tt.bodySmall!
                        .copyWith(color: AppTheme.textOnDarkDim, height: 1.35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Row(
              children: [
                const Icon(Icons.event,
                    size: 14, color: AppTheme.textOnDarkDim),
                const SizedBox(width: 4),
                Text(
                  'Data date · ${_dateFmt.format(date)}',
                  style: tt.labelSmall!.copyWith(color: AppTheme.textOnDarkDim),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Web sidebar ───────────────────────────────────────────────────────────────

class _LayerSidebar extends StatelessWidget {
  const _LayerSidebar({
    required this.layers,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<EnvironmentalLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      width: 280,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgDarkAlt,
          border:
              Border(right: BorderSide(color: AppTheme.borderMid, width: 0.5)),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
          itemCount: layers.length,
          itemBuilder: (_, i) {
            final sel = i == selectedIndex;
            return InkWell(
              onTap: () => onSelect(i),
              child: ColoredBox(
                color: sel
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMD,
                      vertical: AppTheme.spaceSM + 4),
                  child: Row(children: [
                    Icon(_iconFor(layers[i].name),
                        size: 18,
                        color:
                            sel ? AppTheme.primary : AppTheme.textOnDarkMid),
                    const SizedBox(width: AppTheme.spaceSM + 4),
                    Expanded(
                      child: Text(
                        layers[i].name,
                        style: tt.bodyMedium!.copyWith(
                            color: sel
                                ? AppTheme.primary
                                : AppTheme.textOnDarkMid),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Painted backdrop (placeholder + offline fallback) ─────────────────────────

class _HeatmapBackdrop extends StatelessWidget {
  const _HeatmapBackdrop({required this.palette});

  final LayerPalette palette;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.bgDark,
      child: CustomPaint(
        painter: _HeatmapPainter(palette: palette),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({required this.palette});

  final LayerPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 0.5;
    final land = Paint()..color = const Color(0xFF1A3D2E);
    final warm = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x00EF9F27),
          const Color(0xBBEF9F27),
          const Color(0xCCE24B4A),
        ],
      ).createShader(Offset.zero & size);
    final cool = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0x001D9E75), const Color(0xBB1D9E75)],
      ).createShader(Offset.zero & size);
    final cloud = Paint()..color = const Color(0x29FFFFFF);

    for (var x = 0.0; x < size.width; x += size.width / 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    canvas.drawOval(
        Rect.fromLTWH(size.width * .06, size.height * .20, size.width * .26,
            size.height * .24),
        land);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .20, size.height * .54, size.width * .19,
            size.height * .28),
        land);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .47, size.height * .18, size.width * .30,
            size.height * .22),
        land);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .62, size.height * .46, size.width * .20,
            size.height * .32),
        land);

    final accent = palette == LayerPalette.warm ? warm : cool;
    canvas.drawOval(
        Rect.fromLTWH(size.width * .54, size.height * .28, size.width * .28,
            size.height * .26),
        accent);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .14, size.height * .38, size.width * .24,
            size.height * .22),
        accent);

    canvas.drawOval(
        Rect.fromLTWH(size.width * .08, size.height * .10, size.width * .24,
            size.height * .12),
        cloud);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .68, size.height * .16, size.width * .22,
            size.height * .14),
        cloud);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .34, size.height * .70, size.width * .30,
            size.height * .12),
        cloud);
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) => old.palette != palette;
}

// ── Icons ─────────────────────────────────────────────────────────────────────

IconData _iconFor(String name) {
  switch (name) {
    case 'Land Surface Temp':
      return Icons.thermostat;
    case 'Sea Surface Temp':
      return Icons.waves;
    case 'Cloud Cover':
      return Icons.cloud;
    case 'Aerosol / Air Quality':
      return Icons.air;
    case 'UV / Ozone Layer':
      return Icons.wb_sunny;
    case 'Weather Heat Index':
      return Icons.device_thermostat;
    default:
      return Icons.layers;
  }
}
