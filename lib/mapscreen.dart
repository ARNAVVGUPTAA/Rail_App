import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'map_data_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<PoleData> _poles = [];
  List<Polyline> _routePolylines = [];
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _getUserLocation();
  }

  Future<void> _loadData() async {
    final routes = await MapDataService.fetchRoutes();
    final poles = await MapDataService.fetchPoles();
    if (!mounted) return;
    setState(() {
      _routePolylines = routes
          .map((r) => Polyline(
                points: r.coordinates,
                strokeWidth: 3,
                color: Colors.orange,
              ))
          .toList();
      _poles = poles;
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    final pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  void _showAddPoleSheet() async {
    final nameController = TextEditingController();
    final heightController = TextEditingController();
    final cableController = TextEditingController();
    final remarksController = TextEditingController();

    Position pos = await Geolocator.getCurrentPosition();
    LatLng newPosition = LatLng(pos.latitude, pos.longitude);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Add New Pole",
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Pole Name")),
                const SizedBox(height: 12),
                TextField(
                    controller: heightController,
                    decoration: const InputDecoration(labelText: "Height (m)"),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(
                    controller: cableController,
                    decoration:
                        const InputDecoration(labelText: "Cable Distance (m)"),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(labelText: "Remarks")),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text("Save Pole"),
                  onPressed: () async {
                    Navigator.pop(context);
                    await MapDataService.addNewPole(
                      routeId: _poles.isNotEmpty ? _poles.first.routeId : "1",
                      name: nameController.text,
                      position: newPosition,
                      height: double.tryParse(heightController.text),
                      cableDistance: double.tryParse(cableController.text),
                      remarks: remarksController.text,
                    );
                    _loadData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditPoleSheet(PoleData pole) {
    final nameController = TextEditingController(text: pole.name);
    final heightController =
        TextEditingController(text: pole.height.toString());
    final cableController =
        TextEditingController(text: pole.cableDistance?.toString() ?? '');
    final remarksController = TextEditingController(text: pole.remarks);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Edit Pole",
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Pole Name")),
                const SizedBox(height: 12),
                TextField(
                    controller: heightController,
                    decoration: const InputDecoration(labelText: "Height (m)"),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(
                    controller: cableController,
                    decoration:
                        const InputDecoration(labelText: "Cable Distance (m)"),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(labelText: "Remarks")),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text("Update Pole"),
                  onPressed: () async {
                    Navigator.pop(context);
                    await MapDataService.updatePole(
                      poleId: pole.id,
                      name: nameController.text,
                      height: double.tryParse(heightController.text),
                      cableDistance: double.tryParse(cableController.text),
                      remarks: remarksController.text,
                    );
                    _loadData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Tracker & Pole Editor")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation ?? const LatLng(28.6139, 77.2090),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          PolylineLayer(polylines: _routePolylines),
          MarkerLayer(
            markers: [
              if (_userLocation != null)
                Marker(
                  point: _userLocation!,
                  child: const Icon(Icons.person_pin_circle,
                      size: 40, color: Colors.blue),
                ),
              ..._poles.map(
                (pole) => Marker(
                  point: pole.position,
                  child: GestureDetector(
                    onTap: () => _showEditPoleSheet(pole),
                    child: const Icon(Icons.location_on,
                        size: 35, color: Colors.red),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt),
        label: const Text("Add Pole at my Location"),
        onPressed: _showAddPoleSheet,
      ),
    );
  }
}
