import 'package:apprail/mapscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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
              // Marker layer to show a point of interest
              const MarkerLayer(
                markers: [
                  Marker(
                    point: _initialCenter,
                    width: 80,
                    height: 80,
                    child: Icon(
                      Icons.location_pin,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // --- 🚀 NEW BUTTON ADDED HERE 🚀 ---
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Route Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34495E),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Last Maintenance: 01/01/2024',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
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
                      onPressed: () {
                        // Placeholder for navigation or action
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add Inspection button pressed!'),
                          ),
                        );
                      },
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
}
