/// Builds NASA Worldview Snapshots URLs for a given GIBS imagery layer.
///
/// Worldview Snapshots renders a GIBS layer over a bounding box and returns
/// a single static image we can drop into the UI with any plain image widget.
/// Reference: https://wiki.earthdata.nasa.gov/display/GIBS/GIBS+API+for+Developers
class NasaGibsService {
  const NasaGibsService();

  static const _host = 'wvs.earthdata.nasa.gov';
  static const _path = '/api/v1/snapshot';

  /// WMTS tile endpoint (EPSG:3857 / Web Mercator — matches flutter_map's
  /// default CRS and Google Maps). Free, no API key, no registration.
  static const _wmtsBase = 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best';

  /// Builds a flutter_map `urlTemplate` for a GIBS layer's tiles. The `{z}`,
  /// `{x}`, `{y}` placeholders are filled in by flutter_map per tile; GIBS
  /// orders the REST path as TileMatrix/TileRow/TileCol → `{z}/{y}/{x}`.
  String wmtsTemplate({
    required String layerId,
    required String tileMatrixSet,
    String format = 'png',
    DateTime? date,
  }) {
    final stamp = _formatDate(date ?? _defaultDate());
    return '$_wmtsBase/$layerId/default/$stamp/$tileMatrixSet/{z}/{y}/{x}.$format';
  }

  /// Static reference basemap (no time dimension) drawn beneath data layers so
  /// land, ocean and relief are visible even where the science layer is sparse.
  String get basemapTemplate =>
      '$_wmtsBase/BlueMarble_ShadedRelief_Bathymetry/default/'
      'GoogleMapsCompatible_Level8/{z}/{y}/{x}.jpeg';

  /// Coastline + country outlines overlay drawn on top of data layers.
  /// Non-temporal reference layer, so the WMTS path has no date segment.
  String get coastlinesTemplate =>
      '$_wmtsBase/Coastlines_15m/default/'
      'GoogleMapsCompatible_Level13/{z}/{y}/{x}.png';

  /// Global bounding box (S, W, N, E) so the snapshot covers the whole Earth.
  /// The UI wraps the rendered image in an [InteractiveViewer] so the user can
  /// pan + pinch-zoom around the globe — this is what makes the data
  /// "viewable globally" rather than locked to a regional crop.
  static const _bboxGlobal = '-90,-180,90,180';

  /// GIBS imagery is typically published with a 1–3 day lag depending on the
  /// product; offset back to maximise the chance the layer has tiles.
  static const _daysBehind = 3;

  /// Returns a fully-formed snapshot URL for [layerId].
  ///
  /// Always includes the GIBS Coastlines overlay so continent outlines are
  /// visible even when the underlying layer is sparse over land.
  String snapshotUrl({
    required String layerId,
    int width = 1440,
    int height = 720,
    DateTime? date,
  }) {
    final stamp = _formatDate(date ?? _defaultDate());
    final uri = Uri.https(_host, _path, {
      'REQUEST': 'GetSnapshot',
      'LAYERS': '$layerId,Coastlines_15m',
      'CRS': 'EPSG:4326',
      'TIME': stamp,
      'WRAP': 'DAY,X',
      'BBOX': _bboxGlobal,
      'FORMAT': 'image/jpeg',
      'WIDTH': '$width',
      'HEIGHT': '$height',
    });
    return uri.toString();
  }

  static DateTime _defaultDate() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: _daysBehind));
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
