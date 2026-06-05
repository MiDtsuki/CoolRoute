import 'package:flutter_test/flutter_test.dart';
import 'package:cool_route/dummy_data/dummy_data.dart';
import 'package:cool_route/models/environmental_layer.dart';
import 'package:cool_route/services/nasa_gibs_service.dart';

void main() {
  const gibs = NasaGibsService();

  EnvironmentalLayer ozoneBase() =>
      DummyData.layers.firstWhere((l) => l.name == 'UV / Ozone Layer');

  // Simulates EnvironmentalDataService._mergeWeather's copyWith path.
  EnvironmentalLayer ozoneMerged() =>
      ozoneBase().copyWith(status: 'Extreme', value: 'Extreme');

  test('copyWith preserves the ozone GIBS tile config', () {
    final merged = ozoneMerged();
    expect(merged.gibsLayerId, 'OMPS_Ozone_Total_Column');
    expect(merged.gibsTileMatrixSet, 'GoogleMapsCompatible_Level6');
    expect(merged.gibsMaxZoom, 6);
  });

  test('merged ozone layer builds a Level6 URL (not Level7)', () {
    final l = ozoneMerged();
    final url = gibs.wmtsTemplate(
      layerId: l.gibsLayerId!,
      tileMatrixSet: l.gibsTileMatrixSet,
      format: l.gibsFormat,
      date: DateTime.utc(2026, 6, 1),
    );
    expect(url, contains('GoogleMapsCompatible_Level6'));
    expect(url, isNot(contains('Level7')));
    // ignore: avoid_print
    print('OZONE URL: $url');
  });

  test('changing the date changes the URL stamp', () {
    final l = ozoneMerged();
    String urlFor(DateTime d) => gibs.wmtsTemplate(
          layerId: l.gibsLayerId!,
          tileMatrixSet: l.gibsTileMatrixSet,
          format: l.gibsFormat,
          date: d,
        );
    final a = urlFor(DateTime.utc(2026, 6, 1));
    final b = urlFor(DateTime.utc(2026, 5, 25));
    expect(a, contains('2026-06-01'));
    expect(b, contains('2026-05-25'));
    expect(a, isNot(equals(b)));
  });
}
