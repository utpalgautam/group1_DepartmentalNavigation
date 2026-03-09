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
      final floorData = await _firestoreService.getFloorMap(widget.building.id, _selectedFloor);
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
              const SizedBox(height: 24),

              // --- Floor Chips ---
              if (widget.building.totalFloors > 0)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(widget.building.totalFloors, (index) {
                      final isSelected = index == _selectedFloor;
                      final label = index == 0 ? 'G' : '$index';
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GestureDetector(
                          onTap: () => _onFloorSelected(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isSelected
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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
                      ? const Center(child: CircularProgressIndicator(color: Colors.black))
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
      if (_currentFloorData!.mapImageUrl != null && _currentFloorData!.mapImageUrl!.isNotEmpty) {
        return _buildInteractiveLayer(
          child: Image.network(
            _currentFloorData!.mapImageUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            },
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error, size: 40)),
          ),
        );
      } else if (_currentFloorData!.svgMapUrl != null && _currentFloorData!.svgMapUrl!.isNotEmpty) {
        return _buildInteractiveLayer(
          child: SvgPicture.network(
            _currentFloorData!.svgMapUrl!,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => const Center(child: CircularProgressIndicator(color: Colors.black)),
          ),
        );
      } else if (_currentFloorData!.svgMapData != null && _currentFloorData!.svgMapData!.isNotEmpty) {
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
      )
    );
  }

  Widget _buildInteractiveLayer({required Widget child}) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(100), // allows panning past the edges slightly
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: child,
        ),
      ),
    );
  }
}
