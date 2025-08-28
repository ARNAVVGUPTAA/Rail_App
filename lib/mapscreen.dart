import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'map_data_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  late final Future<void> _initFuture;

  List<PoleData> _poles = [];
  List<PoleData> _visiblePoles = []; // Only poles in viewport
  List<Polyline> _routePolylines = [];
  LatLng? _userLocation;

  // Performance optimization variables
  double _currentZoom = 10.0;
  LatLngBounds? _currentBounds;
  Timer? _debounceTimer;
  
  // Clustering settings
  static const double _clusterDistance = 50.0; // pixels
  static const int _maxPolesPerCluster = 10;
  static const double _minZoomForIndividualPoles = 12.0;

  // Use ValueNotifiers to avoid rebuilding entire map
  final ValueNotifier<PoleData?> _selectedPoleNotifier =
      ValueNotifier<PoleData?>(null);
  final ValueNotifier<LatLng?> _userLocationNotifier =
      ValueNotifier<LatLng?>(null);
  final ValueNotifier<int> _markerUpdateTrigger =
      ValueNotifier<int>(0); // Triggers marker rebuilds without setState
  
  PoleData? get _tappedPoleInfo => _selectedPoleNotifier.value;
  PoleData? _nearestPole;
  double? _distanceToNearestPole;
  
  // Connection line from user to selected pole
  final ValueNotifier<Polyline?> _connectionLineNotifier =
      ValueNotifier<Polyline?>(null);
  final ValueNotifier<Polyline?> _searchPolylineNotifier =
      ValueNotifier<Polyline?>(null);

  StreamSubscription<Position>? _positionStream;

  // Performance optimization: Cache markers to avoid rebuilding every frame
  List<Marker>? _cachedPoleMarkers;
  Marker? _cachedUserMarker;
  LatLng? _lastUserLocation;
  PoleData? _lastTappedPole;
  double? _lastZoom;
  LatLngBounds? _lastBounds;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    _selectedPoleNotifier.dispose();
    _userLocationNotifier.dispose();
    _markerUpdateTrigger.dispose();
    _connectionLineNotifier.dispose();
    _searchPolylineNotifier.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _requestPermissions();
    await _loadSupabaseData();
    await _initializeLocationListener();
  }

  // Request all necessary permissions
  Future<void> _requestPermissions() async {
    try {
      // Request multiple permissions at once
      Map<Permission, PermissionStatus> permissions = await [
        Permission.location,
        Permission.locationWhenInUse,
        Permission.notification,
        Permission.storage,
      ].request();

      // Check location permission specifically
      bool locationGranted =
          permissions[Permission.location]?.isGranted == true ||
              permissions[Permission.locationWhenInUse]?.isGranted == true;

      if (!locationGranted) {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Please enable location services in your device settings'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        // Use Geolocator as fallback for location permission
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Location permission is required to show your position on the map'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            _showPermissionDialog();
          }
          return;
        }
      }

      // Check notification permission
      if (permissions[Permission.notification]?.isDenied == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permission denied. You may miss important updates.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions granted! App is ready to use.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show dialog for permanently denied permissions
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'This app needs location permission to show your position on the map and find nearby poles. '
            'Please enable location permission in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadSupabaseData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Show loading notification
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
              Text('🔄 Loading data from Supabase...'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      print('🚀 Fetching data from Supabase...');

      // Fetch routes and poles from Supabase
      final routes = await MapDataService.fetchRoutes();
      final poles = await MapDataService.fetchPoles();

      // Convert routes to polylines
      List<Polyline> tempPolylines = routes.map((route) {
        return Polyline(
          points: route.coordinates,
          strokeWidth: 3.0,
          color: Colors.orangeAccent,
        );
      }).toList();

      _poles = poles;
      _routePolylines = tempPolylines;
      _cachedPoleMarkers = null; // Reset cache

      setState(() {
        _isLoading = false;
      });

      print('✅ Loaded ${routes.length} routes and ${poles.length} poles');

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('✅ Loaded ${routes.length} routes, ${poles.length} poles'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Error loading data: $e');

      Fluttertoast.showToast(
        msg: "Error loading data: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _initializeLocationListener() async {
    try {
      // Double-check permissions before trying to get location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Permissions not available, skip location features
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission denied. You can still view the map and poles.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      Position initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10), // Add timeout
        ),
      );

      if (mounted) {
        // Use ValueNotifier to update location without rebuilding entire map
        _userLocation = LatLng(initialPosition.latitude, initialPosition.longitude);
        _userLocationNotifier.value = _userLocation;
        _findNearestPole();
        // Update connection line when location changes
        _updateConnectionLine();
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 10), // Add timeout for each update
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            // Use ValueNotifier to update location without rebuilding entire map
            _userLocation = LatLng(position.latitude, position.longitude);
            _userLocationNotifier.value = _userLocation;
            _findNearestPole();
            if (_tappedPoleInfo != null) {
              _onPoleTap(_tappedPoleInfo!);
            }
            // Update connection line when location changes
            _updateConnectionLine();
          }
        },
        onError: (error) {
          // Handle location stream errors gracefully
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location update error: $error'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } catch (e) {
      // Handle location errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to get location: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _findNearestPole() {
    final userLocation = _userLocationNotifier.value;
    if (userLocation == null || _poles.isEmpty) return;
    PoleData? nearest;
    double minDistance = double.infinity;
    for (var pole in _poles) {
      final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
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
      orElse: () => PoleData(
        id: '',
        routeId: '',
        name: '',
        position: const LatLng(0, 0),
        height: 0,
        status: '',
      ),
    );

    if (pole.name.isNotEmpty) {
      // Update selected pole without setState
      _selectedPoleNotifier.value = pole;

      // Update search polyline without setState
      final userLocation = _userLocationNotifier.value;
      if (userLocation != null) {
        _searchPolylineNotifier.value = Polyline(
          points: [userLocation, pole.position],
          strokeWidth: 4,
          color: Colors.blueAccent,
        );
      }
      _mapController.move(pole.position, 17.0);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pole not found!")));
    }
  }

  void _onPoleTap(PoleData poleData) {
    if (_userLocationNotifier.value == null) return;
    
    // Only proceed if this is a different pole
    if (_selectedPoleNotifier.value?.id == poleData.id) return;
    
    // Update the selected pole notifier - no setState needed!
    _selectedPoleNotifier.value = poleData;
    // Create connection line from user to selected pole
    _updateConnectionLine();
    // Trigger marker update without setState to show color change
    _triggerMarkerUpdate();
  }

  void _centerOnUser() {
    final userLocation = _userLocationNotifier.value;
    if (userLocation != null) {
      _mapController.move(userLocation, 15.0);
    }
  }

  // Update connection line from user to selected pole
  void _updateConnectionLine() {
    final userLocation = _userLocationNotifier.value;
    if (userLocation == null || _selectedPoleNotifier.value == null) {
      _connectionLineNotifier.value = null;
      return;
    }

    _connectionLineNotifier.value = Polyline(
      points: [userLocation, _selectedPoleNotifier.value!.position],
      strokeWidth: 3.0,
      color: Colors.blue,
      pattern: const StrokePattern.dotted(),
    );
  }

  // Get cache directory path for map tiles
  Future<String> _getCachePath() async {
    final cacheDirectory = await getTemporaryDirectory();
    return cacheDirectory.path;
  }

  // Performance optimization: Build cached pole markers only when needed
  List<Marker> _buildPoleMarkers() {
    // Get current map state
    final zoom = _mapController.camera.zoom;
    final bounds = _mapController.camera.visibleBounds;
    
    // Check if we need to rebuild markers
    bool needsRebuild = _cachedPoleMarkers == null ||
        _lastTappedPole != _selectedPoleNotifier.value ||
        _lastZoom != zoom ||
        _lastBounds != bounds;
    
    if (!needsRebuild) {
      return _cachedPoleMarkers!;
    }

    // Filter poles by viewport for performance
    _visiblePoles = _filterPolesByViewport(bounds);
    
    // Use clustering at lower zoom levels
    if (zoom < _minZoomForIndividualPoles) {
      _cachedPoleMarkers = _buildClusteredMarkers(_visiblePoles, zoom);
    } else {
      // Show individual poles at higher zoom levels, but limit quantity
      final limitedPoles = _visiblePoles.length > 500 
          ? _visiblePoles.take(500).toList() 
          : _visiblePoles;
          
      _cachedPoleMarkers = limitedPoles.map((pole) {
        return Marker(
          width: 30,
          height: 30,
          point: pole.position,
          child: GestureDetector(
            onTap: () => _onPoleTap(pole),
            child: Icon(
              Icons.location_on,
              color: _selectedPoleNotifier.value?.position == pole.position
                  ? Colors.cyanAccent
                  : Colors.redAccent,
            ),
          ),
        );
      }).toList();
    }

    // Update cache keys
    _lastTappedPole = _selectedPoleNotifier.value;
    _lastZoom = zoom;
    _lastBounds = bounds;
    
    return _cachedPoleMarkers!;
  }

  // Filter poles to only those visible in current viewport
  List<PoleData> _filterPolesByViewport(LatLngBounds bounds) {
    return _poles.where((pole) {
      return bounds.contains(pole.position);
    }).toList();
  }

  // Build clustered markers for better performance at low zoom levels
  List<Marker> _buildClusteredMarkers(List<PoleData> poles, double zoom) {
    if (poles.isEmpty) return [];
    
    List<Marker> clusterMarkers = [];
    List<PoleData> processedPoles = [];
    
    for (PoleData pole in poles) {
      if (processedPoles.contains(pole)) continue;
      
      // Find nearby poles for clustering
      List<PoleData> cluster = [pole];
      processedPoles.add(pole);
      
      for (PoleData otherPole in poles) {
        if (processedPoles.contains(otherPole)) continue;
        
        double distance = _calculateDistance(pole.position, otherPole.position);
        double distanceInPixels = distance * 111320 / math.pow(2, zoom); // Rough conversion
        
        if (distanceInPixels < _clusterDistance && cluster.length < _maxPolesPerCluster) {
          cluster.add(otherPole);
          processedPoles.add(otherPole);
        }
      }
      
      // Create cluster marker
      if (cluster.length > 1) {
        clusterMarkers.add(_createClusterMarker(cluster));
      } else {
        clusterMarkers.add(_createSinglePoleMarker(cluster.first));
      }
    }
    
    return clusterMarkers;
  }

  // Create a cluster marker for multiple poles
  Marker _createClusterMarker(List<PoleData> poles) {
    final center = _calculateClusterCenter(poles);
    
    return Marker(
      width: 40,
      height: 40,
      point: center,
      child: GestureDetector(
        onTap: () => _showClusterDialog(poles),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              '${poles.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Create a single pole marker
  Marker _createSinglePoleMarker(PoleData pole) {
    return Marker(
      width: 30,
      height: 30,
      point: pole.position,
      child: GestureDetector(
        onTap: () => _onPoleTap(pole),
        child: Icon(
          Icons.location_on,
          color: _selectedPoleNotifier.value?.position == pole.position
              ? Colors.cyanAccent
              : Colors.redAccent,
        ),
      ),
    );
  }

  // Calculate center point of a cluster
  LatLng _calculateClusterCenter(List<PoleData> poles) {
    double lat = poles.map((p) => p.position.latitude).reduce((a, b) => a + b) / poles.length;
    double lng = poles.map((p) => p.position.longitude).reduce((a, b) => a + b) / poles.length;
    return LatLng(lat, lng);
  }

  // Calculate distance between two points in degrees
  double _calculateDistance(LatLng point1, LatLng point2) {
    return math.sqrt(
      math.pow(point1.latitude - point2.latitude, 2) + 
      math.pow(point1.longitude - point2.longitude, 2)
    );
  }

  // Handle map position changes with debouncing for performance
  void _onMapPositionChanged(MapCamera position, bool hasGesture) {
    _currentZoom = position.zoom;
    _currentBounds = position.visibleBounds;
    
    // Debounce marker updates during gestures for smooth performance
    if (hasGesture) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _triggerMarkerUpdate();
      });
    } else {
      // Immediate update for programmatic moves
      _triggerMarkerUpdate();
    }
  }

  // Trigger marker update without setState - no map flash!
  void _triggerMarkerUpdate() {
    _cachedPoleMarkers = null;
    _markerUpdateTrigger.value = _markerUpdateTrigger.value + 1;
  }

  // Show dialog when cluster is tapped
  void _showClusterDialog(List<PoleData> poles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cluster (${poles.length} poles)'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView.builder(
            itemCount: poles.length,
            itemBuilder: (context, index) {
              final pole = poles[index];
              return ListTile(
                title: Text('Pole ${pole.name}'),
                subtitle: Text('${pole.position.latitude.toStringAsFixed(4)}, ${pole.position.longitude.toStringAsFixed(4)}'),
                onTap: () {
                  Navigator.of(context).pop();
                  _onPoleTap(pole);
                  _mapController.move(pole.position, 15);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Performance optimization: Build cached user marker only when location changes
  Marker? _buildUserMarker() {
    final userLocation = _userLocationNotifier.value;
    if (userLocation == null) return null;

    if (_cachedUserMarker != null && _lastUserLocation == userLocation) {
      return _cachedUserMarker;
    }

    _cachedUserMarker = Marker(
      width: 40,
      height: 40,
      point: userLocation,
      child: const Icon(Icons.person_pin_circle,
          color: Colors.lightBlueAccent, size: 40),
    );

    _lastUserLocation = userLocation;
    return _cachedUserMarker;
  }

  // Build FlutterMap with optional cache support
  Widget _buildFlutterMap(LatLng initialCenter, String? cachePath) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15.0,
        maxZoom: 17.0, // Match TileLayer maxZoom to prevent blank areas
        minZoom: 8.0, // Reasonable minimum zoom for this area
        // Performance optimizations for smoother movement
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        // Add position change callback for debounced marker updates
        onPositionChanged: (MapCamera position, bool hasGesture) {
          _onMapPositionChanged(position, hasGesture);
        },
      ),
      children: [
        // UI: Use OpenStreetMap official tiles with proper attribution
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          retinaMode: true,
          // Add proper user agent and attribution for OpenStreetMap compliance
          additionalOptions: const {
            'attribution': '© OpenStreetMap contributors',
          },
          userAgentPackageName:
              'com.example.railapp/1.0 (contact: dev@railapp.example.com)',
          // Use cached tile provider if cache path is available, otherwise fallback to network
          tileProvider:
              NetworkTileProvider(), // Temporarily disabled cache until we fix the API
          // TODO: Re-enable cache when HiveCacheStore is available
          // tileProvider: cachePath != null
          //     ? CachedTileProvider(
          //         maxStale: const Duration(days: 30),
          //         store: HiveCacheStore(
          //           cachePath,
          //           hiveBoxName: 'HiveCacheStore',
          //         ),
          //       )
          //     : NetworkTileProvider(),
          maxZoom: 18, // Standard OSM max zoom
          minZoom: 3, // Allow reasonable zoom out
          keepBuffer: 3, // Normal buffer for smooth panning
          panBuffer: 1, // Normal pan buffer
          // Better tile error handling
          errorTileCallback: (tile, error, stackTrace) {
            // Handle tile loading errors gracefully
            print('Tile loading error: $error');
          },
          // Tile display settings for smoother rendering
          tileBuilder: (context, tileWidget, tile) {
            return tileWidget;
          },
        ),
        // Only show polylines when zoomed in enough for performance
        if (_currentZoom >= 11.0)
          PolylineLayer(polylines: _routePolylines),
        // Search polyline - optimized with ValueListenableBuilder
        ValueListenableBuilder<Polyline?>(
          valueListenable: _searchPolylineNotifier,
          builder: (context, searchPolyline, child) {
            return searchPolyline != null 
                ? PolylineLayer(polylines: [searchPolyline])
                : const SizedBox.shrink();
          },
        ),
        // Connection line from user to selected pole - optimized with ValueListenableBuilder
        ValueListenableBuilder<Polyline?>(
          valueListenable: _connectionLineNotifier,
          builder: (context, connectionLine, child) {
            return connectionLine != null 
                ? PolylineLayer(polylines: [connectionLine])
                : const SizedBox.shrink();
          },
        ),
        // Performance optimized MarkerLayer - listens to both selection and position changes
        ValueListenableBuilder<int>(
          valueListenable: _markerUpdateTrigger,
          builder: (context, trigger, child) {
            return ValueListenableBuilder<PoleData?>(
              valueListenable: _selectedPoleNotifier,
              builder: (context, selectedPole, child) {
                return MarkerLayer(
                  markers: _buildPoleMarkers(),
                );
              },
            );
          },
        ),
        // Separate MarkerLayer for user location to prevent rebuilding poles
        ValueListenableBuilder<LatLng?>(
          valueListenable: _userLocationNotifier,
          builder: (context, userLocation, child) {
            return MarkerLayer(
              markers: [
                if (userLocation != null) _buildUserMarker()!,
              ],
            );
          },
        ),
        // Add proper attribution for OpenStreetMap compliance
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              onTap: () => print('OpenStreetMap attribution tapped'),
            ),
          ],
        ),
      ],
    );
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
          title: const Text('OHE Poles Map',
              style: TextStyle(color: Colors.white)),
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
              // Wrap FlutterMap with FutureBuilder for cache path
              FutureBuilder<String>(
                future: _getCachePath(),
                builder: (context, cacheSnapshot) {
                  if (cacheSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (cacheSnapshot.hasError || !cacheSnapshot.hasData) {
                    // Fallback to non-cached map if cache path fails
                    return _buildFlutterMap(initialCenter, null);
                  }
                  // Build map with cache support
                  return _buildFlutterMap(initialCenter, cacheSnapshot.data!);
                },
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
                    child: ValueListenableBuilder<PoleData?>(
                      valueListenable: _selectedPoleNotifier,
                      builder: (context, selectedPole, child) {
                        return selectedPole != null
                            ? _buildTappedPoleInfo(titleStyle, bodyStyle)
                            : _buildNearestPoleInfo(titleStyle);
                      },
                    ),
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
              ),
              // Custom positioned floating action button - 10% up from bottom
              Positioned(
                bottom:
                    MediaQuery.of(context).size.height * 0.1, // 10% from bottom
                right: 16,
                child: FloatingActionButton(
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // UI: Pass the text styles into the build methods
  Widget _buildTappedPoleInfo(TextStyle titleStyle, TextStyle bodyStyle) {
    final selectedPole = _selectedPoleNotifier.value!;
    final userLocation = _userLocationNotifier.value;
    final distance = userLocation != null
        ? Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            selectedPole.position.latitude,
            selectedPole.position.longitude)
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pole: ${selectedPole.name}', style: titleStyle),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                _selectedPoleNotifier.value = null;
                _connectionLineNotifier.value = null;
                _triggerMarkerUpdate(); // Refresh markers to remove selection without setState
              },
            )
          ],
        ),
        const SizedBox(height: 8),
        Text('Cable Height: ${selectedPole.height.toStringAsFixed(1)} m',
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
      'Nearest Pole: ${_nearestPole!.name} \n (${(_distanceToNearestPole ?? 0).toStringAsFixed(1)} m away)',
      textAlign: TextAlign.center,
      style: titleStyle,
    );
  }
}
