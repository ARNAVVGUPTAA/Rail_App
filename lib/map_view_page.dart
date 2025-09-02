import 'package:apprail/mapscreen.dart'; // Assuming 'apprail' is your project name
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_data_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  late final MapController _mapController;
  static const _initialCenter = LatLng(28.6139, 77.2090);
  static const _initialZoom = 13.0;

  List<RouteData> _routes = [];
  List<PoleData> _poles = [];
  List<InspectionData> _inspections = [];

  bool _isLoading = false;
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Fetching map data from Supabase...'),
        backgroundColor: Colors.green,
      ),
    );

    try {
      final routes = await MapDataService.fetchRoutes();
      final poles = await MapDataService.fetchPoles();
      final inspections = await MapDataService.fetchInspections();
      setState(() {
        _routes = routes;
        _poles = poles;
        _inspections = inspections;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Data loaded: ${_routes.length} routes, ${_poles.length} poles, ${_inspections.length} inspections'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error loading map data: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MapScreen())),
            tooltip: 'Go to Location Tracker',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              PolylineLayer(
                polylines: _routes.map((route) {
                  return Polyline(
                    points: route.coordinates,
                    strokeWidth: 4.0,
                    color: _selectedRouteId == route.id
                        ? Colors.blueAccent
                        : Colors.green,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: _poles.map((pole) {
                  return Marker(
                    point: pole.position,
                    width: 30,
                    height: 30,
                    child: GestureDetector(
                      onTap: () => _showPoleInfo(pole),
                      child: const Icon(Icons.electrical_services,
                          size: 25, color: Colors.orange),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMapData,
        tooltip: 'Refresh Data',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showPoleInfo(PoleData pole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pole.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Height: ${pole.height}m'),
            // This now works because 'status' exists in PoleData
            Text('Status: ${pole.status}'),
            // This now works because 'lastInspection' exists in PoleData
            if (pole.lastInspection != null)
              Text(
                  'Last Inspection: ${pole.lastInspection!.toLocal().toString().split(' ')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
