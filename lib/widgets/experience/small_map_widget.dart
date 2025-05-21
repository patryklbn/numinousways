import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SmallMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoomLevel;

  const SmallMapWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.zoomLevel = 10,
  }) : super(key: key);

  @override
  _SmallMapWidgetState createState() => _SmallMapWidgetState();
}

class _SmallMapWidgetState extends State<SmallMapWidget> {
  GoogleMapController? _mapController;
  double _currentZoom = 10.0;
  MapType _currentMapType = MapType.normal; // Store map type

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.zoomLevel;
  }

  @override
  void dispose() {
    // Properly dispose of the map controller to prevent view recreation issues
    _mapController?.dispose();
    super.dispose();
  }

  void _zoomIn() async {
    final newZoom = (_currentZoom + 1).clamp(0, 20).toDouble();
    _mapController?.animateCamera(CameraUpdate.zoomTo(newZoom));
    setState(() {
      _currentZoom = newZoom;
    });
  }

  void _zoomOut() async {
    final newZoom = (_currentZoom - 1).clamp(0, 20).toDouble();
    _mapController?.animateCamera(CameraUpdate.zoomTo(newZoom));
    setState(() {
      _currentZoom = newZoom;
    });
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal) ? MapType.satellite : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 300,
          child: GoogleMap(
            // Add a unique key based on latitude and longitude to ensure recreation
            key: ValueKey('map-${widget.latitude}-${widget.longitude}'),
            mapType: _currentMapType,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: widget.zoomLevel,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: {
              Marker(
                markerId: const MarkerId('location_marker'),
                position: LatLng(widget.latitude, widget.longitude),
                infoWindow: const InfoWindow(title: 'Retreat Location'),
              ),
            },
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: "zoom_in_${widget.latitude}_${widget.longitude}",
                onPressed: _zoomIn,
                mini: true,
                backgroundColor: Colors.white,
                child: const Icon(Icons.zoom_in),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "zoom_out_${widget.latitude}_${widget.longitude}",
                onPressed: _zoomOut,
                mini: true,
                backgroundColor: Colors.white,
                child: const Icon(Icons.zoom_out),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "map_toggle_${widget.latitude}_${widget.longitude}",
                onPressed: _toggleMapType,
                mini: true,
                backgroundColor: Colors.white,
                child: const Icon(Icons.map),
              ),
            ],
          ),
        ),
      ],
    );
  }
}