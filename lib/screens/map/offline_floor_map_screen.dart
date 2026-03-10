import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/building_model.dart';
import '../../models/floor_model.dart';
import '../../services/firestore_service.dart';

class OfflineFloorMapScreen extends StatefulWidget {
  final BuildingModel building;

  const OfflineFloorMapScreen({
    super.key,
    required this.building,
  });

  @override
  State<OfflineFloorMapScreen> createState() => _OfflineFloorMapScreenState();
}

class _OfflineFloorMapScreenState extends State<OfflineFloorMapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedFloor = 0; // 0 for G, 1 for 1st floor, etc.
  FloorModel? _currentFloorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFloorData();
  }

  Future<void> _loadFloorData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final floorData = await _firestoreService.getFloorMap(
          widget.building.id, _selectedFloor);
      setState(() {
        _currentFloorData = floorData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentFloorData = null;
      });
    }
  }

  void _onFloorSelected(int floor) {
    if (_selectedFloor != floor) {
      setState(() {
        _selectedFloor = floor;
      });
      _loadFloorData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --- Header ---
              Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      widget.building.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Building Details Card ---
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1D21),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Coordinates
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Coordinates',
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.building.latitude.toStringAsFixed(4)}°N, ${widget.building.longitude.toStringAsFixed(4)}°E',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFF444444),
                    ),

                    const SizedBox(width: 16),

                    // Floors
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.layers_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Floors',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.building.totalFloors}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Floor Dropdown ---
              if (widget.building.totalFloors > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedFloor,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.black),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      items:
                          List.generate(widget.building.totalFloors, (index) {
                        final label =
                            index == 0 ? 'Ground Floor' : 'Floor $index';
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Row(
                            children: [
                              const Icon(Icons.layers_outlined,
                                  size: 18, color: Colors.black54),
                              const SizedBox(width: 10),
                              Text(label),
                            ],
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) _onFloorSelected(value);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // --- Map Container ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.black))
                      : _buildMapContent(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    // If we have actual floor data
    if (_currentFloorData != null) {
      if (_currentFloorData!.mapImageUrl != null &&
          _currentFloorData!.mapImageUrl!.isNotEmpty) {
        return _buildInteractiveLayer(
          child: Image.network(
            _currentFloorData!.mapImageUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                  child: CircularProgressIndicator(color: Colors.black));
            },
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.error, size: 40)),
          ),
        );
      } else if (_currentFloorData!.svgMapUrl != null &&
          _currentFloorData!.svgMapUrl!.isNotEmpty) {
        return _buildInteractiveLayer(
          child: SvgPicture.network(
            _currentFloorData!.svgMapUrl!,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => const Center(
                child: CircularProgressIndicator(color: Colors.black)),
          ),
        );
      } else if (_currentFloorData!.svgMapData != null &&
          _currentFloorData!.svgMapData!.isNotEmpty) {
        return _buildInteractiveLayer(
          child: SvgPicture.string(
            _currentFloorData!.svgMapData!,
            fit: BoxFit.contain,
          ),
        );
      }
    }

    // Fallback placeholder if no data is found
    return _buildInteractiveLayer(
        child: Stack(
      alignment: Alignment.center,
      children: [
        // A subtle grid pattern or empty map indicator
        Container(
          color: const Color(0xFFFAFAFA),
        ),
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Color(0xFFDDDDDD)),
            SizedBox(height: 16),
            Text(
              'Floor Map not available',
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
      ],
    ));
  }

  Widget _buildInteractiveLayer({required Widget child}) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      boundaryMargin:
          const EdgeInsets.all(100), // allows panning past the edges slightly
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: child,
        ),
      ),
    );
  }
}
