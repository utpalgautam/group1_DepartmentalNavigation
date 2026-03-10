import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  MaplibreMapController? _mapController;
  bool _isMapReady = false;

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    setState(() {
      _isMapReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            margin: const EdgeInsets.all(4.0),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: MaplibreMap(
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        initialCameraPosition: const CameraPosition(
          target: LatLng(11.319972, 75.932639),
          zoom: 16.5,
        ),
        styleString: MapStyle.osm,
        myLocationEnabled: _isMapReady,
        myLocationRenderMode: _isMapReady ? MyLocationRenderMode.compass : MyLocationRenderMode.normal,
        compassEnabled: true,
        attributionButtonPosition: AttributionButtonPosition.bottomLeft,
      ),
    );
  }
}

class MapStyle {
  static const String osm = '''
  {
    "version": 8,
    "sources": {
      "osm": {
        "type": "raster",
        "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
        "tileSize": 256,
        "attribution": "© OpenStreetMap contributors"
      }
    },
    "layers": [
      {
        "id": "osm",
        "type": "raster",
        "source": "osm",
        "minzoom": 0,
        "maxzoom": 19
      }
    ]
  }
  ''';
}
