import '../models/cool_spot.dart';
import '../models/environmental_layer.dart';
import '../models/heat_risk.dart';
import '../models/hot_zone_report.dart';
import '../models/nearby_report.dart';
import '../models/route_option.dart';
import '../models/user_profile.dart';
import '../models/weather_info.dart';

class DummyData {
  static const weather = WeatherInfo(
    location: 'Bangkok, Thailand',
    temperatureC: 36,
    feelsLikeC: 41,
    humidity: 70,
    uvIndex: 'High',
    condition: 'Hazy sun',
  );

  static const userProfile = UserProfile(
    id: 'user_nicha_001',
    name: 'Nicha',
    role: 'University Student',
    location: 'Bangkok, Thailand',
    riskProfile: 'Normal',
    savedRoutes: [
      'Dormitory to Library',
      'Main Gate to Cafeteria',
      'Library to Bus Stop',
    ],
    reportCount: 5,
    verifiedReportCount: 18,
  );

  static const routes = [
    RouteOption(
      name: 'Fastest Route',
      duration: '8 min',
      distance: '720 m',
      shadeLevel: 'Low',
      summary: 'Passes 2 reported hot zones',
      risk: HeatRisk.high,
    ),
    RouteOption(
      name: 'Cooler Route',
      duration: '11 min',
      distance: '940 m',
      shadeLevel: 'High',
      summary: 'Passes 1 water refill station and shaded walkway',
      risk: HeatRisk.medium,
      badge: 'Recommended',
    ),
    RouteOption(
      name: 'Indoor Cut-through',
      duration: '13 min',
      distance: '1.2 km',
      shadeLevel: 'Very High',
      summary: 'Uses mall and library indoor path',
      risk: HeatRisk.low,
    ),
  ];

  static const hotZones = [
    HotZoneReport(
      title: 'Engineering Building Walkway',
      location: 'Engineering Faculty, East Wing',
      category: 'Exposed concrete',
      description: 'Long exposed concrete walkway with no overhead shade. '
          'Heat radiates from the pavement surface throughout the afternoon.',
      timeAgo: '25 min ago',
      verifications: 8,
      risk: HeatRisk.extreme,
      x: .38,
      y: .52,
    ),
    HotZoneReport(
      title: 'Radiating pavement near Main Gate',
      location: 'Main Gate Bus Stop',
      category: 'Exposed pavement',
      description: 'Little shade and slow traffic heat make this stop feel unsafe after noon.',
      timeAgo: '18 min ago',
      verifications: 14,
      risk: HeatRisk.extreme,
      x: .27,
      y: .38,
    ),
    HotZoneReport(
      title: 'Cafeteria walkway heat pocket',
      location: 'Cafeteria Walkway',
      category: 'Low airflow',
      description: 'Crowded walkway with metal roofing and very low airflow.',
      timeAgo: '42 min ago',
      verifications: 8,
      risk: HeatRisk.medium,
      x: .62,
      y: .58,
    ),
    HotZoneReport(
      title: 'Dormitory Road sun exposure',
      location: 'Dormitory Road',
      category: 'No shade',
      description: 'Long exposed segment. Use library-side path if possible.',
      timeAgo: '1 hr ago',
      verifications: 6,
      risk: HeatRisk.high,
      x: .76,
      y: .30,
    ),
    HotZoneReport(
      title: 'Broken water station near court',
      location: 'Sports Court Walkway',
      category: 'Broken water station',
      description: 'Water refill point is unavailable, leaving a long exposed walk without hydration support.',
      timeAgo: '1 hr 25 min ago',
      verifications: 11,
      risk: HeatRisk.high,
      x: .48,
      y: .72,
    ),
    HotZoneReport(
      title: 'Crowded outdoor queue',
      location: 'Cafeteria Entrance',
      category: 'Crowded outdoor area',
      description: 'Students queue under partial sun with limited airflow during lunch hours.',
      timeAgo: '2 hr ago',
      verifications: 9,
      risk: HeatRisk.medium,
      x: .68,
      y: .46,
    ),
  ];

  static const nearbyReports = [
    NearbyReport(
      id: 'nearby_001',
      title: 'No shade at bus stop',
      location: 'Main Gate Bus Stop',
      distance: '90 m',
      risk: HeatRisk.extreme,
      timeAgo: '12 min ago',
      verifications: 24,
    ),
    NearbyReport(
      id: 'nearby_002',
      title: 'Heat trapped under metal roof',
      location: 'Cafeteria Walkway',
      distance: '140 m',
      risk: HeatRisk.high,
      timeAgo: '28 min ago',
      verifications: 13,
    ),
    NearbyReport(
      id: 'nearby_003',
      title: 'Water refill station offline',
      location: 'Sports Court Walkway',
      distance: '220 m',
      risk: HeatRisk.high,
      timeAgo: '44 min ago',
      verifications: 10,
    ),
    NearbyReport(
      id: 'nearby_004',
      title: 'Exposed crossing near dormitory',
      location: 'Dormitory Road',
      distance: '310 m',
      risk: HeatRisk.medium,
      timeAgo: '1 hr ago',
      verifications: 7,
    ),
    NearbyReport(
      id: 'nearby_005',
      title: 'Crowded sunny queue',
      location: 'Cafeteria Entrance',
      distance: '420 m',
      risk: HeatRisk.medium,
      timeAgo: '2 hr ago',
      verifications: 9,
    ),
  ];

  static const coolSpots = [
    CoolSpot(
      name: 'University Library',
      type: 'Air-conditioned',
      distance: '250 m',
      amenity: 'Quiet cooling area',
      openStatus: 'Open',
      verifiedBy: 42,
      x: .43,
      y: .46,
    ),
    CoolSpot(
      name: 'Water Refill Station',
      type: 'Water',
      distance: '180 m',
      amenity: 'Cold refill point',
      openStatus: 'Working',
      verifiedBy: 18,
      x: .34,
      y: .64,
    ),
    CoolSpot(
      name: 'Tree Covered Walkway',
      type: 'Shade',
      distance: '120 m',
      amenity: 'Dense tree shade',
      openStatus: 'Available',
      verifiedBy: 31,
      x: .55,
      y: .34,
    ),
    CoolSpot(
      name: '7-Eleven',
      type: 'Indoor cooling',
      distance: '300 m',
      amenity: 'AC and drinks',
      openStatus: 'Open',
      verifiedBy: 12,
      x: .72,
      y: .68,
    ),
    CoolSpot(
      name: 'Shopping Mall Entrance',
      type: 'Indoor cooling',
      distance: '420 m',
      amenity: 'AC lobby and shaded pickup area',
      openStatus: 'Open',
      verifiedBy: 27,
      x: .82,
      y: .52,
    ),
    CoolSpot(
      name: 'Student Center Shade Deck',
      type: 'Shade',
      distance: '210 m',
      amenity: 'Covered seating and fans',
      openStatus: 'Available',
      verifiedBy: 22,
      x: .24,
      y: .54,
    ),
  ];

  static const layers = [
    EnvironmentalLayer(
      name: 'Land Surface Temp',
      source: 'NASA GIBS · MODIS Terra',
      status: 'Elevated over paved areas',
      value: '41.8 C',
      gibsLayerId: 'MODIS_Terra_Land_Surface_Temp_Day',
    ),
    EnvironmentalLayer(
      name: 'Sea Surface Temp',
      source: 'NASA GIBS · GHRSST MUR',
      status: 'Warm regional waters',
      value: '30.4 C',
      gibsLayerId: 'GHRSST_L4_MUR_Sea_Surface_Temperature',
      palette: LayerPalette.cool,
    ),
    EnvironmentalLayer(
      name: 'Cloud Cover',
      source: 'NASA GIBS · MODIS Terra',
      status: 'Limited afternoon relief',
      value: '18%',
      gibsLayerId: 'MODIS_Terra_Cloud_Fraction_Day',
      palette: LayerPalette.cool,
    ),
    EnvironmentalLayer(
      name: 'Aerosol / Air Quality',
      source: 'NASA GIBS · MODIS Terra',
      status: 'Moderate haze signal',
      value: 'Medium',
      gibsLayerId: 'MODIS_Terra_Aerosol',
    ),
    EnvironmentalLayer(
      name: 'UV / Ozone Layer',
      source: 'NASA GIBS · AIRS · WeatherAPI',
      status: 'Avoid direct exposure',
      value: 'Extreme',
      gibsLayerId: 'AIRS_Total_Ozone_Daily_Day',
    ),
    EnvironmentalLayer(
      name: 'Weather Heat Index',
      source: 'WeatherAPI · MODIS LST',
      status: 'Hydration breaks advised',
      value: '42 C',
      gibsLayerId: 'MODIS_Terra_Land_Surface_Temp_Day',
    ),
  ];
}
