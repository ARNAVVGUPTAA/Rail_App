import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

class MapDataService {
  static final _supabase = Supabase.instance.client;

  // Table names matching your Supabase database
  static const String _routesTableName = 'cable_routes';
  static const String _polesTableName = 'ohe_poles';
  static const String _inspectionsTableName = 'inspections';

  // Fetch routes from cable_routes table
  static Future<List<RouteData>> fetchRoutes() async {
    try {
      print('🔄 Fetching routes from Supabase...');
      
      List<RouteData> allRoutes = [];
      int batchSize = 1000;
      int offset = 0;
      bool hasMore = true;
      
      while (hasMore) {
        final response = await _supabase
            .from(_routesTableName)
            .select()
            .order('last_updated', ascending: false)
            .range(offset, offset + batchSize - 1);
        
        final batchRoutes = (response as List).map((route) => RouteData.fromMap(route)).toList();
        allRoutes.addAll(batchRoutes);
        
        // If we got less than batchSize, we've reached the end
        hasMore = batchRoutes.length == batchSize;
        offset += batchSize;
        
        print('📦 Fetched batch: ${batchRoutes.length} routes (total: ${allRoutes.length})');
      }

      print('✅ Fetched ${allRoutes.length} routes from Supabase');
      return allRoutes;
    } catch (e) {
      print('❌ Error fetching routes: $e');
      return [];
    }
  }

  // Fetch poles from ohe_poles table
  static Future<List<PoleData>> fetchPoles({String? routeId}) async {
    try {
      print('🔄 Fetching poles from Supabase...');
      
      List<PoleData> allPoles = [];
      int batchSize = 1000;
      int offset = 0;
      bool hasMore = true;
      
      while (hasMore) {
        var query = _supabase.from(_polesTableName).select();

        if (routeId != null) {
          query = query.eq('route_id', routeId);
        }

        final response = await query
            .order('pole_no', ascending: true)
            .range(offset, offset + batchSize - 1);
        
        final batchPoles = (response as List).map((pole) => PoleData.fromMap(pole)).toList();
        allPoles.addAll(batchPoles);
        
        // If we got less than batchSize, we've reached the end
        hasMore = batchPoles.length == batchSize;
        offset += batchSize;
        
        print('📦 Fetched batch: ${batchPoles.length} poles (total: ${allPoles.length})');
      }

      print('✅ Fetched ${allPoles.length} poles from Supabase');
      return allPoles;
    } catch (e) {
      print('❌ Error fetching poles: $e');
      return [];
    }
  }

  // Fetch inspections from inspections table
  static Future<List<InspectionData>> fetchInspections(
      {String? routeId}) async {
    try {
      print('🔄 Fetching inspections from Supabase...');
      
      List<InspectionData> allInspections = [];
      int batchSize = 1000;
      int offset = 0;
      bool hasMore = true;
      
      while (hasMore) {
        var query = _supabase.from(_inspectionsTableName).select();

        if (routeId != null) {
          query = query.eq('route_id', routeId);
        }

        final response = await query
            .order('performed_at', ascending: false)
            .range(offset, offset + batchSize - 1);
        
        final batchInspections = (response as List)
            .map((inspection) => InspectionData.fromMap(inspection))
            .toList();
        allInspections.addAll(batchInspections);
        
        // If we got less than batchSize, we've reached the end
        hasMore = batchInspections.length == batchSize;
        offset += batchSize;
        
        print('📦 Fetched batch: ${batchInspections.length} inspections (total: ${allInspections.length})');
      }

      print('✅ Fetched ${allInspections.length} inspections from Supabase');
      return allInspections;
    } catch (e) {
      print('❌ Error fetching inspections: $e');
      return [];
    }
  }

  // Add new inspection to Supabase
  static Future<bool> addInspection(InspectionData inspection) async {
    try {
      await _supabase.from(_inspectionsTableName).insert(inspection.toMap());
      return true;
    } catch (e) {
      print('Error adding inspection: $e');
      return false;
    }
  }
}

// Data models
class RouteData {
  final String id;
  final String name;
  final String? description;
  final List<LatLng> coordinates;
  final DateTime? lastMaintenance;
  final String status;
  final String routeType;

  RouteData({
    required this.id,
    required this.name,
    this.description,
    required this.coordinates,
    this.lastMaintenance,
    required this.status,
    required this.routeType,
  });

  factory RouteData.fromMap(Map<String, dynamic> map) {
    return RouteData(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? 'Unknown Route',
      description: map['type']?.toString(),
      coordinates: _parseCoordinates(map['geom'] ?? {}),
      lastMaintenance: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : null,
      status: 'active',
      routeType: map['type'] ?? 'all',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': description,
      'geom': _coordinatesToGeoJSON(coordinates),
      'last_updated': lastMaintenance?.toIso8601String(),
    };
  }

  static List<LatLng> _parseCoordinates(dynamic coords) {
    try {
      if (coords is Map) {
        // Handle GeoJSON format
        if (coords['type'] == 'LineString' && coords['coordinates'] is List) {
          final coordList = coords['coordinates'] as List;
          return coordList.map((coord) {
            if (coord is List && coord.length >= 2) {
              final lat = _parseNumber(coord[1]);
              final lng = _parseNumber(coord[0]);
              return LatLng(lat, lng);
            }
            return const LatLng(0, 0);
          }).toList();
        }

        // Handle MultiLineString format - flatten all LineStrings into one list
        if (coords['type'] == 'MultiLineString' &&
            coords['coordinates'] is List) {
          final multiLineList = coords['coordinates'] as List;
          List<LatLng> allCoords = [];

          for (var lineString in multiLineList) {
            if (lineString is List) {
              for (var coord in lineString) {
                if (coord is List && coord.length >= 2) {
                  final lat = _parseNumber(coord[1]);
                  final lng = _parseNumber(coord[0]);
                  allCoords.add(LatLng(lat, lng));
                }
              }
            }
          }
          return allCoords;
        }

        // Handle generic coordinates array
        if (coords['coordinates'] is List) {
          final coordList = coords['coordinates'] as List;
          if (coordList.isNotEmpty && coordList.first is List) {
            return coordList.map((coord) {
              if (coord is List && coord.length >= 2) {
                final lat = _parseNumber(coord[1]);
                final lng = _parseNumber(coord[0]);
                return LatLng(lat, lng);
              }
              return const LatLng(0, 0);
            }).toList();
          }
        }
      }

      if (coords is List) {
        return coords.map((coord) {
          if (coord is Map) {
            final lat = _parseNumber(coord['lat'] ?? coord['latitude'] ?? 0.0);
            final lng = _parseNumber(coord['lng'] ?? coord['longitude'] ?? 0.0);
            return LatLng(lat, lng);
          } else if (coord is List && coord.length >= 2) {
            final lat = _parseNumber(coord[1]);
            final lng = _parseNumber(coord[0]);
            return LatLng(lat, lng);
          }
          return const LatLng(0, 0);
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error parsing coordinates: $e');
      print('🔍 Coords data type: ${coords.runtimeType}');
      print('🔍 Coords content: $coords');
      return [];
    }
  }

  static Map<String, dynamic> _coordinatesToGeoJSON(List<LatLng> coordinates) {
    return {
      'type': 'LineString',
      'coordinates': coordinates
          .map((coord) => [coord.longitude, coord.latitude])
          .toList(),
    };
  }
}

// Helper method to safely parse numbers from various formats
double _parseNumber(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  if (value is List) {
    print('⚠️ Unexpected list found where number expected: $value');
    return 0.0;
  }
  return 0.0;
}

class PoleData {
  final String id;
  final String routeId;
  final String name;
  final LatLng position;
  final double height;
  final String status;
  final DateTime? lastInspection;

  PoleData({
    required this.id,
    required this.routeId,
    required this.name,
    required this.position,
    required this.height,
    required this.status,
    this.lastInspection,
  });

  factory PoleData.fromMap(Map<String, dynamic> map) {
    return PoleData(
      id: map['id']?.toString() ?? '',
      routeId: map['route_id']?.toString() ?? '',
      name: map['pole_no']?.toString() ?? 'Unknown Pole',
      position: _parsePosition(map['geom']),
      height: (map['height_m'] ?? 0.0).toDouble(),
      status: 'active',
      lastInspection: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'pole_no': name,
      'geom': {
        'type': 'Point',
        'coordinates': [position.longitude, position.latitude],
      },
      'height_m': height,
    };
  }

  static LatLng _parsePosition(dynamic geom) {
    try {
      if (geom is Map) {
        if (geom['type'] == 'Point' && geom['coordinates'] is List) {
          final coords = geom['coordinates'] as List;
          if (coords.length >= 2) {
            final lat = _parseNumber(coords[1]);
            final lng = _parseNumber(coords[0]);
            return LatLng(lat, lng);
          }
        }
        final lat = _parseNumber(geom['lat'] ?? geom['latitude'] ?? 0.0);
        final lng = _parseNumber(geom['lng'] ?? geom['longitude'] ?? 0.0);
        if (lat != 0.0 || lng != 0.0) {
          return LatLng(lat, lng);
        }
      }
      return const LatLng(28.6139, 77.2090); // Default to Delhi
    } catch (e) {
      print('❌ Error parsing position: $e');
      print('🔍 Geom data: $geom');
      return const LatLng(28.6139, 77.2090); // Default to Delhi
    }
  }
}

class InspectionData {
  final String? id;
  final String routeId;
  final String? poleId;
  final String inspectorName;
  final DateTime inspectionDate;
  final String status;
  final String? notes;
  final List<String>? photos;

  InspectionData({
    this.id,
    required this.routeId,
    this.poleId,
    required this.inspectorName,
    required this.inspectionDate,
    required this.status,
    this.notes,
    this.photos,
  });

  factory InspectionData.fromMap(Map<String, dynamic> map) {
    return InspectionData(
      id: map['id']?.toString(),
      routeId: map['route_id']?.toString() ?? '',
      poleId: map['user_id']?.toString(),
      inspectorName: 'Inspector',
      inspectionDate: DateTime.parse(
          map['performed_at'] ?? DateTime.now().toIso8601String()),
      status: 'completed',
      notes: map['notes'],
      photos: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'route_id': routeId,
      if (poleId != null) 'user_id': poleId,
      'performed_at': inspectionDate.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}
