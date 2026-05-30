import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/layer_chip_bar.dart';

class EnvironmentalDataScreen extends StatefulWidget {
  const EnvironmentalDataScreen({super.key});

  @override
  State<EnvironmentalDataScreen> createState() => _EnvironmentalDataScreenState();
}

class _EnvironmentalDataScreenState extends State<EnvironmentalDataScreen> {
  int _selected = 0;

  void _select(int i) => setState(() => _selected = i);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 800;
    final layer = _layers[_selected];
    final labels = _layers.map((l) => l.name).toList();

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceSM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Environmental data',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge!
                    .copyWith(color: AppTheme.textOnDark),
              ),
              const SizedBox(height: 4),
              Text(
                'NASA GIBS · Weather API',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: AppTheme.textOnDarkDim),
              ),
            ],
          ),
        ),
        Expanded(
          child: _VizPanel(
            layer: layer,
            labels: labels,
            selectedIndex: _selected,
            onSelect: _select,
          ),
        ),
        _InfoPanel(layer: layer),
      ],
    );

    return ColoredBox(
      color: AppTheme.bgDark,
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LayerSidebar(
                    layers: _layers, selectedIndex: _selected, onSelect: _select),
                Expanded(child: body),
              ],
            )
          : body,
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
  });

  final _LayerData layer;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: AppTheme.bgDark,
          child: CustomPaint(
            painter: _HeatmapPainter(layerIndex: labels.indexOf(layer.name)),
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
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: AppTheme.spaceMD,
                      top: AppTheme.spaceXS,
                      bottom: AppTheme.spaceSM),
                  child: Text(
                    'NASA GIBS + Weather API dummy layer',
                    style: tt.labelSmall!.copyWith(color: AppTheme.textOnDarkDim),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info panel (compact) ──────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.layer});

  final _LayerData layer;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppTheme.bgDarkAlt,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(layer.name, style: tt.headlineMedium!.copyWith(color: AppTheme.primary)),
            const SizedBox(height: AppTheme.spaceMD),
            const _LegendBar(),
          ],
        ),
      ),
    );
  }
}

// ── Legend bar ────────────────────────────────────────────────────────────────

class _LegendBar extends StatelessWidget {
  const _LegendBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            gradient: const LinearGradient(
              colors: [
                AppTheme.markerBlue,
                AppTheme.primary,
                AppTheme.riskMedium,
                AppTheme.riskExtreme,
              ],
            ),
          ),
          child: const SizedBox(height: 10),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cool',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(color: AppTheme.textOnDarkDim),
            ),
            Text(
              'Hot',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(color: AppTheme.textOnDarkDim),
            ),
          ],
        ),
      ],
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

  final List<_LayerData> layers;
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
          border: Border(
              right: BorderSide(color: AppTheme.borderMid, width: 0.5)),
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
                      horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM + 4),
                  child: Row(children: [
                    Icon(layers[i].icon,
                        size: 18,
                        color: sel ? AppTheme.primary : AppTheme.textOnDarkMid),
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

// ── Heatmap painter ───────────────────────────────────────────────────────────

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({required this.layerIndex});

  final int layerIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 0.5;
    final land = Paint()..color = const Color(0xFF1A3D2E);
    final heatA = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x00EF9F27),
          const Color(0xBBEF9F27),
          const Color(0xCCE24B4A),
        ],
      ).createShader(Offset.zero & size);
    final heatB = Paint()
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
        Rect.fromLTWH(size.width * .06, size.height * .20,
            size.width * .26, size.height * .24),
        land);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .20, size.height * .54,
            size.width * .19, size.height * .28),
        land);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .47, size.height * .18,
            size.width * .30, size.height * .22),
        land);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .62, size.height * .46,
            size.width * .20, size.height * .32),
        land);

    final useWarm = layerIndex != 1 && layerIndex != 2;
    canvas.drawOval(
        Rect.fromLTWH(size.width * .54, size.height * .28,
            size.width * .28, size.height * .26),
        useWarm ? heatA : heatB);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .14, size.height * .38,
            size.width * .24, size.height * .22),
        useWarm ? heatA : heatB);

    canvas.drawOval(
        Rect.fromLTWH(size.width * .08, size.height * .10,
            size.width * .24, size.height * .12),
        cloud);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .68, size.height * .16,
            size.width * .22, size.height * .14),
        cloud);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .34, size.height * .70,
            size.width * .30, size.height * .12),
        cloud);
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) => old.layerIndex != layerIndex;
}

// ── Layer data ────────────────────────────────────────────────────────────────

class _LayerData {
  const _LayerData({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}

const _layers = [
  _LayerData(name: 'Land Surface Temp', icon: Icons.thermostat),
  _LayerData(name: 'Sea Surface Temp', icon: Icons.waves),
  _LayerData(name: 'Cloud Cover', icon: Icons.cloud),
  _LayerData(name: 'Aerosol / Air Quality', icon: Icons.air),
  _LayerData(name: 'UV / Ozone Layer', icon: Icons.wb_sunny),
  _LayerData(name: 'Weather Heat Index', icon: Icons.device_thermostat),
];
