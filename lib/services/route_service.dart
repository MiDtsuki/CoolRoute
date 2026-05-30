import '../dummy_data/dummy_data.dart';
import '../models/route_option.dart';

class RouteService {
  Future<List<RouteOption>> getRouteOptions() async {
    return DummyData.routes;
  }
}
