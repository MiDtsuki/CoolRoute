import 'package:flutter/material.dart';

import '../../dummy_data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/route_option_card.dart';
import 'route_details_screen.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key, this.initialSelectedRouteName});

  final String? initialSelectedRouteName;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  @override
  void initState() {
    super.initState();
    final name = widget.initialSelectedRouteName;
    if (name != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$name loaded as selected route.')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 850;

    final form = _FormPanel();
    final results = _ResultsPanel(
      mapHeight: MediaQuery.sizeOf(context).height * (wide ? 0.50 : 0.35),
      onRouteSelect: (route) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => RouteDetailsScreen(route: route)),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 360, child: form),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(child: results),
                  ],
                )
              : Column(children: [form, const SizedBox(height: 18), results]),
        ),
      ),
    );
  }
}

// ── Form panel ────────────────────────────────────────────────────────────────

class _FormPanel extends StatelessWidget {
  const _FormPanel();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Heat-safe route', style: tt.headlineMedium),
            const SizedBox(height: AppTheme.spaceMD - 2),
            const TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.my_location_outlined),
                labelText: 'Start',
                hintText: 'Current location',
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM + 4),
            const TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.flag_outlined),
                labelText: 'Destination',
                hintText: 'University Library',
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM + 4),
            DropdownButtonFormField<String>(
              initialValue: 'Now',
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.schedule_outlined),
                labelText: 'Depart',
              ),
              items: const [
                DropdownMenuItem(value: 'Now', child: Text('Now')),
                DropdownMenuItem(value: 'In 30 minutes', child: Text('In 30 minutes')),
                DropdownMenuItem(value: 'This evening', child: Text('This evening')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: AppTheme.spaceMD),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Find safer route'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Results panel ─────────────────────────────────────────────────────────────

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.mapHeight, required this.onRouteSelect});

  final double mapHeight;
  final ValueChanged<dynamic> onRouteSelect;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RouteMapPreview(height: mapHeight),
        const SizedBox(height: AppTheme.spaceMD),
        Text('Suggested routes', style: tt.labelLarge),
        const SizedBox(height: AppTheme.spaceSM + 2),
        for (final route in DummyData.routes) ...[
          RouteOptionCard(
            route: route,
            onSelect: onRouteSelect,
          ),
          const SizedBox(height: AppTheme.spaceSM + 2),
        ],
      ],
    );
  }
}

// ── Map preview ───────────────────────────────────────────────────────────────

class _RouteMapPreview extends StatelessWidget {
  const _RouteMapPreview({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _RoutePreviewPainter(),
          child: Stack(
            children: [
              Positioned(
                left: AppTheme.spaceMD,
                top: AppTheme.spaceMD,
                child: _MapLabel(icon: Icons.my_location_outlined, text: 'Start', tt: tt),
              ),
              Positioned(
                right: AppTheme.spaceMD,
                bottom: AppTheme.spaceMD,
                child: _MapLabel(icon: Icons.flag_outlined, text: 'Destination', tt: tt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.icon, required this.text, required this.tt});

  final IconData icon;
  final String text;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceSM + 4, vertical: AppTheme.spaceXS + 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: AppTheme.spaceXS + 2),
            Text(text, style: tt.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _RoutePreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppTheme.mapBg;
    canvas.drawRect(Offset.zero & size, bg);

    final road = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final fastest = Paint()
      ..color = AppTheme.markerOrange
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cooler = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final indoor = Paint()
      ..color = AppTheme.markerBlue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(size.width * .10, size.height * .25),
        Offset(size.width * .88, size.height * .78), road);
    canvas.drawLine(Offset(size.width * .18, size.height * .82),
        Offset(size.width * .72, size.height * .12), road);
    canvas.drawLine(Offset(size.width * .08, size.height * .55),
        Offset(size.width * .92, size.height * .48), road);

    final direct = Path()
      ..moveTo(size.width * .18, size.height * .30)
      ..quadraticBezierTo(
          size.width * .52, size.height * .40, size.width * .82, size.height * .72);
    final safe = Path()
      ..moveTo(size.width * .18, size.height * .30)
      ..cubicTo(size.width * .30, size.height * .72, size.width * .62,
          size.height * .18, size.width * .82, size.height * .72);
    final indoorPath = Path()
      ..moveTo(size.width * .18, size.height * .30)
      ..lineTo(size.width * .36, size.height * .34)
      ..lineTo(size.width * .48, size.height * .62)
      ..lineTo(size.width * .82, size.height * .72);

    canvas.drawPath(direct, fastest);
    canvas.drawPath(safe, cooler);
    canvas.drawPath(indoorPath, indoor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
