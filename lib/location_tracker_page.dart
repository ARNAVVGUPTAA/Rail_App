import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationTrackerPage extends StatefulWidget {
  const LocationTrackerPage({super.key});

  @override
  State<LocationTrackerPage> createState() => LocationTrackerPageState();
}

class LocationTrackerPageState extends State<LocationTrackerPage> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _masts = [];
  String? _selectedMast;
  LatLng? _selectedLatLng;
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
    _getCurrentLocation();
  }

  Future<void> _loadGeoJson() async {
    final data =
        await rootBundle.loadString('assets/geojson/lucknow_network.geojson');
    final jsonResult = json.decode(data);

    List<Map<String, dynamic>> mastList = [];
    for (var feature in jsonResult['features']) {
      final props = feature['properties'];
      final coords = feature['geometry']['coordinates'];
      if (feature['geometry']['type'] == 'Point') {
        mastList.add({
          "mast": props['Name'] ?? "Unknown",
          "latlng": LatLng(coords[1], coords[0]),
        });
      }
    }

    if (mounted) {
      setState(() {
        _masts = mastList;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
      });
    }
  }

  void _zoomToMast(Map<String, dynamic> mast) {
    final target = mast["latlng"] as LatLng;
    setState(() {
      _selectedMast = mast["mast"];
      _selectedLatLng = target;
    });
    _mapController.move(target, 16.0);
  }

  double? _calculateDistance(LatLng mast) {
    if (_currentLatLng == null) return null;
    return Geolocator.distanceBetween(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      mast.latitude,
      mast.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance =
        _selectedLatLng != null ? _calculateDistance(_selectedLatLng!) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("OHE Mast Locator"),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            // REPLACED with Flutter's built-in Autocomplete widget
            child: Autocomplete<Map<String, dynamic>>(
              // This function provides the suggestions
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<Map<String, dynamic>>.empty();
                }
                return _masts.where((mast) {
                  return mast["mast"]
                      .toString()
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              // This function tells the widget what to display in the text field
              displayStringForOption: (option) => option['mast'],
              // This function is called when a suggestion is selected
              onSelected: (selection) {
                _zoomToMast(selection);
              },
              // This builds the text field UI
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Search Mast No (e.g. 762/25)",
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(26.8467, 80.9462), // Lucknow
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    if (_selectedLatLng != null)
                      Marker(
                        point: _selectedLatLng!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 40),
                      ),
                    if (_currentLatLng != null)
                      Marker(
                        point: _currentLatLng!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.my_location,
                            color: Colors.blue, size: 30),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_selectedLatLng != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "Selected Mast: $_selectedMast\n"
                "Distance: ${distance != null ? '${(distance / 1000).toStringAsFixed(2)} km' : 'Calculating...'}",
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
