import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late final Future<void> _initFuture;

  List<Map<String, dynamic>> _poles = [];
  List<Polyline> _routePolylines = [];
  LatLng? _userLocation;

  Map<String, dynamic>? _searchedPole;
  Map<String, dynamic>? _nearestPole;
  double? _distanceToNearestPole;
  Polyline? _searchPolyline;

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadGeoJSON();
    await _initializeLocationListener();
  }

  Future<void> _loadGeoJSON() async {
    try {
      final data =
          await rootBundle.loadString('assets/lucknow_network.geojson');
      final geoJson = json.decode(data);
      final features = geoJson['features'] as List;

      List<Map<String, dynamic>> tempPoles = [];
      List<Polyline> tempPolylines = [];

      for (var feature in features) {
        final geometry = feature['geometry'];
        final type = geometry['type'];
        final coords = geometry['coordinates'];
        final properties = feature['properties'];

        if (type == 'Point') {
          // MODIFIED: Logic to parse 'description' for DataID
          String description = properties['description'] ?? '';
          String dataId = 'N/A';
          // Use a regular expression to find the number after "DataID: "
          final match = RegExp(r'DataID: (\d+)').firstMatch(description);
          if (match != null) {
            dataId = match.group(1)!;
          }

          tempPoles.add({
            'name': properties['Name'] ?? 'Unknown Pole',
            'data_id': dataId, // Storing the extracted DataID
            'lat': coords[1].toDouble(),
            'lng': coords[0].toDouble(),
          });
        } else if (type == 'LineString') {
          final points = (coords as List)
              .map((point) => LatLng(point[1].toDouble(), point[0].toDouble()))
              .toList();
          tempPolylines.add(Polyline(
            points: points,
            strokeWidth: 3,
            color: Colors.orangeAccent,
          ));
        }
      }

      _poles = tempPoles;
      _routePolylines = tempPolylines;
    } catch (e) {
      throw Exception("Failed to load or parse GeoJSON data: $e");
    }
  }

  Future<void> _initializeLocationListener() async {
    try {
      // ... (permission handling logic)
      Position initialPosition = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation =
              LatLng(initialPosition.latitude, initialPosition.longitude);
        });
        _findNearestPole();
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best, distanceFilter: 10),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
            _findNearestPole();
          });
        }
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  void _findNearestPole() {
    if (_userLocation == null || _poles.isEmpty) return;

    Map<String, dynamic>? nearest;
    double minDistance = double.infinity;

    for (var pole in _poles) {
      final poleLocation = LatLng(pole['lat'], pole['lng']);
      final distance = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          poleLocation.latitude,
          poleLocation.longitude);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = pole;
      }
    }

    if (mounted) {
      setState(() {
        _nearestPole = nearest;
        _distanceToNearestPole = minDistance;
      });
    }
  }

  void _searchPole(String name) {
    if (name.isEmpty) return;

    final pole = _poles.firstWhere(
      (p) => (p['name'] as String).toLowerCase().contains(name.toLowerCase()),
      orElse: () => <String, dynamic>{},
    );

    if (pole.isNotEmpty) {
      final poleLocation = LatLng(pole['lat'], pole['lng']);
      setState(() {
        _searchedPole = pole;
        if (_userLocation != null) {
          _searchPolyline = Polyline(
            points: [_userLocation!, poleLocation],
            strokeWidth: 4,
            color: Colors.blueAccent,
          );
        }
      });
      _mapController.move(poleLocation, 17.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pole not found!")),
      );
    }
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OHE Poles Map')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error initializing map: ${snapshot.error}'),
              ),
            );
          }

          final initialCenter = _poles.isNotEmpty
              ? LatLng(_poles.first['lat'], _poles.first['lng'])
              : const LatLng(26.8467, 80.9462);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  PolylineLayer(polylines: _routePolylines),
                  if (_searchPolyline != null)
                    PolylineLayer(polylines: [_searchPolyline!]),
                  MarkerLayer(
                    markers: [
                      ..._poles.map((pole) {
                        return Marker(
                          width: 30,
                          height: 30,
                          point: LatLng(pole['lat'], pole['lng']),
                          child:
                              const Icon(Icons.location_on, color: Colors.red),
                        );
                      }),
                      if (_userLocation != null)
                        Marker(
                          width: 40,
                          height: 40,
                          point: _userLocation!,
                          child: const Icon(Icons.person_pin_circle,
                              color: Colors.blue, size: 40),
                        ),
                      if (_searchedPole != null)
                        Marker(
                          width: 40,
                          height: 40,
                          point: LatLng(
                              _searchedPole!['lat'], _searchedPole!['lng']),
                          child: const Icon(Icons.location_on,
                              color: Colors.green, size: 40),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Card(
                  elevation: 4,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter OHE pole name (e.g., 0/2)',
                      fillColor: Colors.white,
                      filled: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _searchPole(_searchController.text),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (value) => _searchPole(value),
                  ),
                ),
              ),
              if (_nearestPole != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        // You can now display the DataID as well
                        'Nearest Pole: ${_nearestPole!['name']} (ID: ${_nearestPole!['data_id']}) - (${_distanceToNearestPole?.toStringAsFixed(1)} m away)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUser,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
