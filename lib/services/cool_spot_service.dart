import '../dummy_data/dummy_data.dart';
import '../models/cool_spot.dart';

class CoolSpotService {
  Future<List<CoolSpot>> getCoolSpots() async {
    return DummyData.coolSpots;
  }
}
