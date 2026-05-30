import '../dummy_data/dummy_data.dart';
import '../models/hot_zone_report.dart';
import '../models/nearby_report.dart';

class ReportService {
  Future<List<HotZoneReport>> getHotZoneReports() async {
    return DummyData.hotZones;
  }

  Future<List<NearbyReport>> getNearbyReports() async {
    return DummyData.nearbyReports;
  }
}
