/// Builds NASA Worldview Snapshots URLs for a given GIBS imagery layer.
///
/// Worldview Snapshots renders a GIBS layer over a bounding box and returns
/// a single static image we can drop into the UI with any plain image widget.
/// Reference: https://wiki.earthdata.nasa.gov/display/GIBS/GIBS+API+for+Developers
class NasaGibsService {
  const NasaGibsService();

  static const _host = 'wvs.earthdata.nasa.gov';
  static const _path = '/api/v1/snapshot';

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
