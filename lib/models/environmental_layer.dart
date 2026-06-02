enum LayerPalette { warm, cool }

class EnvironmentalLayer {
  const EnvironmentalLayer({
    required this.name,
    required this.source,
    required this.status,
    required this.value,
    this.gibsLayerId,
    this.palette = LayerPalette.warm,
  });

  final String name;
  final String source;
  final String status;
  final String value;

  /// NASA GIBS layer identifier used to fetch the satellite snapshot.
  /// Null for layers that don't have a corresponding GIBS product
  /// (e.g. the derived Weather Heat Index — that one shows LST imagery).
  final String? gibsLayerId;

  final LayerPalette palette;
}
