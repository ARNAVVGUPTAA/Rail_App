import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// A simple data class to hold pole information
class Pole {
  final LatLng position;
  final String name;
  final String dataId;
  final double height;

  Pole(
      {required this.position,
      required this.name,
      required this.dataId,
      required this.height});
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late final Future<void> _initFuture;

  List<Pole> _poles = [];
  List<Polyline> _routePolylines = [];
  LatLng? _userLocation;

  Pole? _tappedPoleInfo;
  Pole? _nearestPole;
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

      List<Pole> tempPoles = [];
      List<Polyline> tempPolylines = [];

      for (var feature in features) {
        final geometry = feature['geometry'];
        final type = geometry['type'];
        final coords = geometry['coordinates'];
        final properties = feature['properties'];

        if (type == 'Point') {
          String description = properties['description'] ?? '';

          String dataId = 'N/A';
          double height = 5.5;

          final dataIdMatch = RegExp(r'DataID: (\d+)').firstMatch(description);
          if (dataIdMatch != null) {
            dataId = dataIdMatch.group(1)!;
          }

          final altMatch = RegExp(r'Alt: ([\d.]+)').firstMatch(description);
          if (altMatch != null) {
            height = double.tryParse(altMatch.group(1)!) ?? 5.5;
          }

          tempPoles.add(Pole(
            name: properties['Name'] ?? 'Unknown Pole',
            dataId: dataId,
            position: LatLng(coords[1].toDouble(), coords[0].toDouble()),
            height: height,
          ));
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
      Position initialPosition = await Geolocator.getCurrentPosition();
      if (mounted) {
        _userLocation =
            LatLng(initialPosition.latitude, initialPosition.longitude);
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
            if (_tappedPoleInfo != null) {
              _onPoleTap(_tappedPoleInfo!);
            }
          });
        }
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  void _findNearestPole() {
    if (_userLocation == null || _poles.isEmpty) return;
    Pole? nearest;
    double minDistance = double.infinity;
    for (var pole in _poles) {
      final distance = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          pole.position.latitude,
          pole.position.longitude);
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
      (p) => p.name.toLowerCase().contains(name.toLowerCase()),
      orElse: () =>
          Pole(position: const LatLng(0, 0), name: '', dataId: '', height: 0),
    );

    if (pole.name.isNotEmpty) {
      setState(() {
        _tappedPoleInfo = pole;
        if (_userLocation != null) {
          _searchPolyline = Polyline(
            points: [_userLocation!, pole.position],
            strokeWidth: 4,
            color: Colors.blueAccent,
          );
        }
      });
      _mapController.move(pole.position, 17.0);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pole not found!")));
    }
  }

  void _onPoleTap(Pole poleData) {
    if (_userLocation == null) return;
    setState(() => _tappedPoleInfo = poleData);
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI: Define reusable text styles for a consistent look
    const titleStyle = TextStyle(
        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
    const bodyStyle = TextStyle(fontSize: 16, color: Colors.white70);

    return Scaffold(
      // UI: Change AppBar color
      appBar: AppBar(
          title: const Text('OHE Poles Map', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 21, 49, 77),
          iconTheme: const IconThemeData(color: Colors.white)),
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
                    child: Text('Error: ${snapshot.error}')));
          }
          final initialCenter = _poles.isNotEmpty
              ? _poles.first.position
              : const LatLng(26.8467, 80.9462);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 15.0,
                  // Performance optimizations for smoother movement
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  // Reduce animation duration for snappier feel
                  onMapEvent: (MapEvent mapEvent) {
                    // Optional: Handle map events if needed
                  },
                ),
                children: [
                  // UI: Use a light/greyish map tile with enhanced caching
                  TileLayer(
                    urlTemplate:
                        "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                    subdomains: const ['a', 'b', 'c'],
                    retinaMode: true,
                    // Enhanced caching and performance settings
                    tileProvider: NetworkTileProvider(),
                    maxZoom: 19,
                    keepBuffer: 3, // Increased buffer for smoother panning
                    panBuffer: 1, // Reduce pan buffer to decrease memory usage
                    // Tile display settings for smoother rendering
                    tileBuilder: (context, tileWidget, tile) {
                      return tileWidget;
                    },
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
                          point: pole.position,
                          child: GestureDetector(
                            onTap: () => _onPoleTap(pole),
                            child: Icon(
                              Icons.location_on,
                              // UI: Change marker color
                              color: _tappedPoleInfo?.position == pole.position
                                  ? Colors.cyanAccent
                                  : Colors.redAccent,
                            ),
                          ),
                        );
                      }),
                      if (_userLocation != null)
                        Marker(
                          width: 40,
                          height: 40,
                          point: _userLocation!,
                          child: const Icon(Icons.person_pin_circle,
                              color: Colors.lightBlueAccent, size: 40),
                        ),
                    ],
                  ),
                ],
              ),
              // Search Bar
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Card(
                  // UI: Make the search bar a rounded "pill" shape
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter OHE pole name...',
                      // UI: Remove the border
                      border: InputBorder.none,
                      // UI: Add some padding and an icon
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                    ),
                    onSubmitted: (value) => _searchPole(value),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  // UI: Style the info panel card
                  elevation: 8,
                  color: const Color(0xFF2C3E50)
                      .withOpacity(0.9), // Dark, slightly transparent
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _tappedPoleInfo != null
                        ? _buildTappedPoleInfo(titleStyle, bodyStyle)
                        : _buildNearestPoleInfo(titleStyle),
                  ),
                ),
              ),
              Positioned(
                bottom: 200,
                right: 15,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "zoomIn",
                      mini: true,
                      onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: "zoomOut",
                      mini: true,
                      onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1),
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              )
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

  // UI: Pass the text styles into the build methods
  Widget _buildTappedPoleInfo(TextStyle titleStyle, TextStyle bodyStyle) {
    final distance = _userLocation != null
        ? Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            _tappedPoleInfo!.position.latitude,
            _tappedPoleInfo!.position.longitude)
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pole: ${_tappedPoleInfo!.name}', style: titleStyle),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _tappedPoleInfo = null),
            )
          ],
        ),
        const SizedBox(height: 8),
        Text('Data ID: ${_tappedPoleInfo!.dataId}', style: bodyStyle),
        Text('Cable Height: ${_tappedPoleInfo!.height.toStringAsFixed(1)} m',
            style: bodyStyle),
        Text(
            'Distance: ${distance != null ? '${distance.toStringAsFixed(1)} m away' : 'Calculating...'}',
            style: bodyStyle),
      ],
    );
  }

  Widget _buildNearestPoleInfo(TextStyle titleStyle) {
    if (_nearestPole == null) {
      return Text("Calculating nearest pole...",
          textAlign: TextAlign.center, style: titleStyle);
    }
    return Text(
      'Nearest Pole: ${_nearestPole!.name} (${(_distanceToNearestPole ?? 0).toStringAsFixed(1)} m away)',
      textAlign: TextAlign.center,
      style: titleStyle,
    );
  }
}
