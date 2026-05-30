import '../dummy_data/dummy_data.dart';
import '../models/environmental_layer.dart';

class EnvironmentalDataService {
  Future<List<EnvironmentalLayer>> getEnvironmentalLayers() async {
    return DummyData.layers;
  }
}
