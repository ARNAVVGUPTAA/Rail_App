import 'package:apprail/mapscreen.dart';
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
  // Controller for the map
  late final MapController _mapController;

  // Initial map values centered on Delhi, India
  static const _initialCenter = LatLng(28.6139, 77.2090);
  static const _initialZoom = 13.0;

  // State for the filter buttons
  int _selectedFilterIndex = 0;

  // Data lists
  List<RouteData> _routes = [];
  List<PoleData> _poles = [];
  List<InspectionData> _inspections = [];

  // Loading state
  bool _isLoading = false;
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _isLoading = true;
    });

    // Show prominent loading notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('🔄 Fetching map data from Supabase...'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    print('🚀 Starting Supabase data fetch...');

    try {
      // Fetch data sequentially to show progress
      print('📍 Fetching routes...');
      final routes = await MapDataService.fetchRoutes();
      setState(() {
        _routes = routes;
      });

      print('🔌 Fetching poles...');
      final poles = await MapDataService.fetchPoles();
      setState(() {
        _poles = poles;
      });

      print('📋 Fetching inspections...');
      final inspections = await MapDataService.fetchInspections();
      setState(() {
        _inspections = inspections;
        _isLoading = false;
      });

      print('✅ All data loaded successfully!');

      // Show success notification with prominent styling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ Data loaded from Supabase!',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        '${_routes.length} routes, ${_poles.length} poles, ${_inspections.length} inspections'),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Error loading data: $e');

      Fluttertoast.showToast(
        msg: "Error loading map data: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );

      // Also show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('❌ Failed to load from Supabase',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Check your internet connection and database'),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadMapData,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar styled to match the rest of the app
      appBar: AppBar(
        title: const Text(
          'Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C3E50), // Dark blue-gray color
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Using a Stack to overlay widgets on the map
      body: Stack(
        children: [
          // Loading progress bar at the top
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ),

          // Connection status indicator
          if (_isLoading)
            Positioned(
              top: 10,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading from Supabase...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // The map widget fills the entire screen
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
            ),
            children: [
              // Map tiles from OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.app', // Replace with your app's package name
              ),

              // Route polylines
              if (_routes.isNotEmpty)
                PolylineLayer(
                  polylines: _routes.map((route) {
                    return Polyline(
                      points: route.coordinates,
                      strokeWidth: _selectedFilterIndex == 0
                          ? 5.0
                          : 3.0, // Macro vs Micro
                      color: _selectedRouteId == route.id
                          ? Colors.blueAccent
                          : Colors.green,
                    );
                  }).toList(),
                ),

              // Pole markers
              if (_poles.isNotEmpty &&
                  (_selectedFilterIndex == 1 || _selectedFilterIndex == 2))
                MarkerLayer(
                  markers: _poles.map((pole) {
                    return Marker(
                      point: pole.position,
                      width: 30,
                      height: 30,
                      child: GestureDetector(
                        onTap: () => _showPoleInfo(pole),
                        child: const Icon(
                          Icons.electrical_services,
                          size: 25,
                          color: Colors.orange,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Inspection markers (positioned based on poles or route coordinates)
              if (_inspections.isNotEmpty && _selectedFilterIndex == 2)
                MarkerLayer(
                  markers: _inspections.map((inspection) {
                    Color markerColor = inspection.status == 'completed'
                        ? Colors.green
                        : inspection.status == 'pending'
                            ? Colors.orange
                            : Colors.red;

                    // Find position from related pole or route
                    LatLng position = _getInspectionPosition(inspection);

                    return Marker(
                      point: position,
                      width: 25,
                      height: 25,
                      child: GestureDetector(
                        onTap: () => _showInspectionInfo(inspection),
                        child: Icon(
                          Icons.assignment,
                          size: 20,
                          color: markerColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // --- 🚀 NEW BUTTON ADDED HERE 🚀 ---
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'locationTrackerFab',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MapScreen(),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF2C3E50),
                  tooltip: 'Go to Location Tracker',
                  child: const Icon(Icons.track_changes, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'refreshFab',
                  onPressed: _loadMapData,
                  backgroundColor: Colors.blueAccent,
                  tooltip: 'Refresh Map Data',
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
          // ------------------------------------

          // The bottom information panel
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: const Color(0xFF2C3E50), // Dark background for the card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filter buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFilterChip(context, 'Macro', 0),
                        _buildFilterChip(context, 'Micro', 1),
                        _buildFilterChip(context, 'All', 2),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Route information
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _routes.isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedRouteId != null
                                          ? _routes
                                              .firstWhere(
                                                  (r) =>
                                                      r.id == _selectedRouteId,
                                                  orElse: () => _routes.first)
                                              .name
                                          : _routes.first.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF34495E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedRouteId != null
                                          ? _routes
                                                      .firstWhere(
                                                          (r) =>
                                                              r.id ==
                                                              _selectedRouteId,
                                                          orElse: () =>
                                                              _routes.first)
                                                      .lastMaintenance !=
                                                  null
                                              ? 'Last Maintenance: ${_routes.firstWhere((r) => r.id == _selectedRouteId, orElse: () => _routes.first).lastMaintenance!.toLocal().toString().split(' ')[0]}'
                                              : 'No maintenance records'
                                          : _routes.first.lastMaintenance !=
                                                  null
                                              ? 'Last Maintenance: ${_routes.first.lastMaintenance!.toLocal().toString().split(' ')[0]}'
                                              : 'No maintenance records',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Routes: ${_routes.length} | Poles: ${_poles.length} | Inspections: ${_inspections.length}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                )
                              : const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No Route Data',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF34495E),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'No data available from Supabase',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                    ),
                    const SizedBox(height: 16),
                    // "Add Inspection" button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _routes.isNotEmpty
                          ? () => _showAddInspectionDialog()
                          : null,
                      child: const Text(
                        'Add Inspection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the filter chips
  Widget _buildFilterChip(BuildContext context, String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilterIndex = index;
          });
        }
      },
      backgroundColor: Colors.grey.shade700,
      selectedColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade600,
        ),
      ),
    );
  }

  // Helper method to get inspection position from pole or route
  LatLng _getInspectionPosition(InspectionData inspection) {
    // Try to find the position from pole data
    if (inspection.poleId != null) {
      final pole = _poles.firstWhere(
        (pole) => pole.id == inspection.poleId,
        orElse: () => _poles.first,
      );
      return pole.position;
    }

    // Fall back to route data
    final route = _routes.firstWhere(
      (route) => route.id == inspection.routeId,
      orElse: () => _routes.first,
    );

    // Return first coordinate of the route
    return route.coordinates.isNotEmpty
        ? route.coordinates.first
        : _initialCenter;
  }

  // Show pole information dialog
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
            Text('Status: ${pole.status}'),
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to inspection page for this pole
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Inspect ${pole.name}')),
              );
            },
            child: const Text('Inspect'),
          ),
        ],
      ),
    );
  }

  // Show inspection information dialog
  void _showInspectionInfo(InspectionData inspection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inspection Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inspector: ${inspection.inspectorName}'),
            Text(
                'Date: ${inspection.inspectionDate.toLocal().toString().split(' ')[0]}'),
            Text('Status: ${inspection.status}'),
            if (inspection.notes != null) Text('Notes: ${inspection.notes}'),
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

  // Show add inspection dialog
  void _showAddInspectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Inspection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This would open a form to add a new inspection.'),
            const SizedBox(height: 16),
            Text('Available Routes: ${_routes.length}'),
            Text('Available Poles: ${_poles.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to inspection form page
              // You can replace this with navigation to your inspection form
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inspection form would open here'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
