enum LayerPalette { warm, cool }

class EnvironmentalLayer {
  const EnvironmentalLayer({
    required this.name,
    required this.source,
    required this.status,
    required this.value,
    required this.blurb,
    this.gibsLayerId,
    this.gibsTileMatrixSet = 'GoogleMapsCompatible_Level7',
    this.gibsMaxZoom = 7,
    this.gibsFormat = 'png',
    this.gibsMonthly = false,
    this.palette = LayerPalette.warm,
  });

  final String name;
  final String source;
  final String status;
  final String value;

  /// One-sentence plain-language explanation of what this index measures and
  /// why it matters for heat exposure. Shown under the value in the info panel.
  final String blurb;

  /// NASA GIBS layer identifier used to fetch the satellite imagery.
  /// Null for layers that don't have a corresponding GIBS product
  /// (e.g. the derived Weather Heat Index — that one shows LST imagery).
  final String? gibsLayerId;

  /// WMTS tile-matrix set for this product. Each GIBS layer is published at a
  /// fixed maximum resolution, e.g. `GoogleMapsCompatible_Level7`.
  final String gibsTileMatrixSet;

  /// Deepest zoom level GIBS serves real tiles for. flutter_map upscales
  /// beyond this rather than requesting tiles that would 404.
  final int gibsMaxZoom;

  /// Tile image format — science layers are usually `png` (with transparency),
  /// true-colour imagery is `jpeg`.
  final String gibsFormat;

  /// True for monthly-composite products (e.g. NDVI). Their current-month tiles
  /// aren't published until the month closes, so the tile date is snapped back
  /// to a completed, available month.
  final bool gibsMonthly;

  final LayerPalette palette;
}
