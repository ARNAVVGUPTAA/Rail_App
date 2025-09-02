import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

// ===========================
// DATA SERVICE CLASS
// ===========================
class MapDataService {
  static final _supabase = Supabase.instance.client;

  // Table names
  static const String _routesTableName = 'cable_routes';
  static const String _polesTableName = 'ohe_poles';
  // FIX: Added table name for inspections
  static const String _inspectionsTableName = 'inspections';

  // ===========================
  // FETCH ROUTES
  // ===========================
  static Future<List<RouteData>> fetchRoutes() async {
    try {
      final response = await _supabase.from(_routesTableName).select();
      return (response as List)
          .map((route) => RouteData.fromMap(route))
          .toList();
    } catch (e) {
      // Avoid print in production code
      return [];
    }
  }

  // ===========================
  // FETCH POLES
  // ===========================
  static Future<List<PoleData>> fetchPoles({String? routeId}) async {
    try {
      var query = _supabase.from(_polesTableName).select();

      if (routeId != null) {
        query = query.eq('route_id', routeId);
      }

      final response = await query.order('pole_no', ascending: true);
      return (response as List).map((pole) => PoleData.fromMap(pole)).toList();
    } catch (e) {
      return [];
    }
  }

  // ===========================
  // FETCH INSPECTIONS (FIX: ADDED MISSING METHOD)
  // ===========================
  static Future<List<InspectionData>> fetchInspections() async {
    try {
      final response = await _supabase.from(_inspectionsTableName).select();
      return (response as List)
          .map((i) => InspectionData.fromMap(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ===========================
  // ADD NEW POLE
  // ===========================
  static Future<bool> addNewPole({
    required String routeId,
    required String name,
    required LatLng position,
    double? height,
    double? cableDistance,
    String? remarks,
  }) async {
    try {
      await _supabase.from(_polesTableName).insert({
        'route_id': routeId,
        'pole_no': name,
        'geom': {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude],
        },
        'height_m': height,
        'cable_distance': cableDistance,
        'remarks': remarks,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===========================
  // UPDATE EXISTING POLE
  // ===========================
  static Future<bool> updatePole({
    required String poleId,
    String? name,
    double? height,
    double? cableDistance,
    String? remarks,
    LatLng? position,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['pole_no'] = name;
      if (height != null) updateData['height_m'] = height;
      if (cableDistance != null) updateData['cable_distance'] = cableDistance;
      if (remarks != null) updateData['remarks'] = remarks;
      if (position != null) {
        updateData['geom'] = {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude],
        };
      }

      await _supabase.from(_polesTableName).update(updateData).eq('id', poleId);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// ===========================
// DATA MODELS
// ===========================

class RouteData {
  final String id;
  final String name;
  final List<LatLng> coordinates;
  // FIX: Added missing field
  final DateTime? lastMaintenance;

  RouteData({
    required this.id,
    required this.name,
    required this.coordinates,
    this.lastMaintenance, // FIX: Added to constructor
  });

  factory RouteData.fromMap(Map<String, dynamic> map) {
    return RouteData(
      id: map['id'].toString(),
      name: map['name'] ?? 'Unknown Route',
      // FIX: Added the logic to parse coordinates from a LineString geometry
      coordinates: _parseLineString(map['geom']),
      // FIX: Added parsing for the new field
      // IMPORTANT: Change 'last_maintenance' to your actual column name
      lastMaintenance: map['last_maintenance'] != null
          ? DateTime.tryParse(map['last_maintenance'])
          : null,
    );
  }

  static List<LatLng> _parseLineString(dynamic geom) {
    if (geom is Map && geom['type'] == 'LineString') {
      final coords = geom['coordinates'] as List;
      return coords
          .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
          .toList();
    }
    return [];
  }
}

class PoleData {
  final String id;
  final String routeId;
  final String name;
  final LatLng position;
  final double height;
  final double? cableDistance;
  final String? remarks;
  // FIX: Added missing fields
  final String status;
  final DateTime? lastInspection;

  PoleData({
    required this.id,
    required this.routeId,
    required this.name,
    required this.position,
    required this.height,
    this.cableDistance,
    this.remarks,
    required this.status, // FIX: Added to constructor
    this.lastInspection, // FIX: Added to constructor
  });

  factory PoleData.fromMap(Map<String, dynamic> map) {
    return PoleData(
      id: map['id'].toString(),
      routeId: map['route_id']?.toString() ?? '',
      name: map['pole_no']?.toString() ?? 'Unknown Pole',
      position: _parsePosition(map['geom']),
      height: (map['height_m'] ?? 0.0).toDouble(),
      cableDistance: (map['cable_distance'] ?? 0.0).toDouble(),
      remarks: map['remarks'],
      // FIX: Added parsing for new fields
      // IMPORTANT: Change 'status' and 'last_inspection' to your actual column names
      status: map['status'] ?? 'Unknown',
      lastInspection: map['last_inspection'] != null
          ? DateTime.tryParse(map['last_inspection'])
          : null,
    );
  }

  static LatLng _parsePosition(dynamic geom) {
    if (geom is Map && geom['type'] == 'Point') {
      final coords = geom['coordinates'] as List;
      return LatLng(coords[1].toDouble(), coords[0].toDouble());
    }
    return const LatLng(0, 0); // Default fallback
  }
}

// FIX: Added the entire missing InspectionData class
class InspectionData {
  final String id;
  final String routeId;
  final String? poleId;
  final String inspectorName;
  final DateTime inspectionDate;
  final String status;
  final String? notes;

  InspectionData({
    required this.id,
    required this.routeId,
    this.poleId,
    required this.inspectorName,
    required this.inspectionDate,
    required this.status,
    this.notes,
  });

  factory InspectionData.fromMap(Map<String, dynamic> map) {
    return InspectionData(
      id: map['id']?.toString() ?? '',
      routeId: map['route_id']?.toString() ?? '',
      poleId: map['pole_id']?.toString(),
      inspectorName: map['inspector_name'] ?? 'N/A',
      inspectionDate: DateTime.parse(map['inspection_date']),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
    );
  }
}
