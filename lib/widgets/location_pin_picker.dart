import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LocationPinPicker extends StatefulWidget {
  const LocationPinPicker({
    super.key,
    required this.label,
    required this.pinColor,
    required this.pinIcon,
    this.initialX = .52,
    this.initialY = .48,
    this.onChanged,
  });

  final String label;
  final Color pinColor;
  final IconData pinIcon;
  final double initialX;
  final double initialY;
  final ValueChanged<Offset>? onChanged;

  @override
  State<LocationPinPicker> createState() => _LocationPinPickerState();
}

class _LocationPinPickerState extends State<LocationPinPicker> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = Offset(widget.initialX, widget.initialY);
  }

  void _setPosition(Offset localPosition, Size size) {
    final next = Offset(
      (localPosition.dx / size.width).clamp(.06, .94),
      (localPosition.dy / size.height).clamp(.08, .92),
    );
    setState(() => _position = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: tt.labelLarge),
        const SizedBox(height: AppTheme.spaceSM),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapDown: (details) =>
                      _setPosition(details.localPosition, size),
                  onPanUpdate: (details) =>
                      _setPosition(details.localPosition, size),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _MiniMapCanvas()),
                      Positioned(
                        left: _position.dx * size.width,
                        top: _position.dy * size.height,
                        child: Transform.translate(
                          offset: const Offset(-18, -18),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: widget.pinColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.bgCard,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spaceSM),
                              child: Icon(
                                widget.pinIcon,
                                color: AppTheme.textOnDark,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppTheme.spaceSM,
                        bottom: AppTheme.spaceSM,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusPill,
                            ),
                            border: Border.all(
                              color: AppTheme.borderLight,
                              width: .5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceSM,
                              vertical: AppTheme.spaceXS,
                            ),
                            child: Text(
                              'Tap or drag to place pin',
                              style: tt.labelSmall,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMapCanvas extends StatelessWidget {
  const _MiniMapCanvas();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MiniMapPainter());
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppTheme.mapBg;
    final park = Paint()..color = const Color(0xFFD4E8D8);
    final block = Paint()..color = const Color(0xFFCDD5D0);
    final road = Paint()
      ..color = AppTheme.bgCard
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final minorRoad = Paint()
      ..color = AppTheme.bgCard
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .08,
          size.height * .12,
          size.width * .28,
          size.height * .22,
        ),
        const Radius.circular(AppTheme.radiusMD),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .62,
          size.height * .58,
          size.width * .25,
          size.height * .24,
        ),
        const Radius.circular(AppTheme.radiusMD),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .50,
          size.height * .14,
          size.width * .22,
          size.height * .18,
        ),
        const Radius.circular(AppTheme.radiusSM),
      ),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .18,
          size.height * .62,
          size.width * .22,
          size.height * .18,
        ),
        const Radius.circular(AppTheme.radiusSM),
      ),
      block,
    );

    canvas.drawLine(
      Offset(size.width * .06, size.height * .72),
      Offset(size.width * .94, size.height * .28),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .20, size.height * .12),
      Offset(size.width * .80, size.height * .88),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .12, size.height * .50),
      Offset(size.width * .88, size.height * .55),
      minorRoad,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
