import 'package:flutter_test/flutter_test.dart';
import 'package:dept_nav_app/models/floor_model.dart';
import 'package:dept_nav_app/services/astar_service.dart';

void main() {
  group('AStarService Tests', () {
    late IndoorGraph testGraph;

    setUp(() {
      testGraph = IndoorGraph(
        buildingId: 'b1',
        floorNo: 0,
        nodes: [
          GraphNode(id: 'n1', label: 'Entrance', x: 0.1, y: 0.1, type: 'entrance'),
          GraphNode(id: 'n2', label: 'Hallway 1', x: 0.3, y: 0.1, type: 'hallway'),
          GraphNode(id: 'n3', label: 'Hallway 2', x: 0.3, y: 0.5, type: 'hallway'),
          GraphNode(id: 'n4', label: 'Cabin 101', x: 0.6, y: 0.5, type: 'room'),
          GraphNode(id: 'n5', label: 'Stairs', x: 0.1, y: 0.5, type: 'stairs'),
        ],
        edges: [
          GraphEdge(from: 'n1', to: 'n2', weight: 1.0),
          GraphEdge(from: 'n2', to: 'n3', weight: 1.0),
          GraphEdge(from: 'n3', to: 'n4', weight: 1.0),
          GraphEdge(from: 'n1', to: 'n5', weight: 1.5),
          GraphEdge(from: 'n5', to: 'n3', weight: 1.0),
        ],
      );
    });

    test('Find path from Entrance to Cabin 101', () {
      final path = AStarService.findPath(testGraph, 'n1', 'n4');
      
      expect(path, isNotEmpty);
      expect(path.first.id, 'n1');
      expect(path.last.id, 'n4');
      // Should prefer shorter path: n1 -> n2 -> n3 -> n4 (weight 3)
      // vs n1 -> n5 -> n3 -> n4 (weight 3.5)
      expect(path.length, 4);
      expect(path[1].id, 'n2');
    });

    test('Find path using labels', () {
      final path = AStarService.findPath(testGraph, 'Entrance', 'Cabin 101');
      
      expect(path, isNotEmpty);
      expect(path.first.label, 'Entrance');
      expect(path.last.label, 'Cabin 101');
    });

    test('No path found', () {
      final disconnectedGraph = IndoorGraph(
        buildingId: 'b1',
        floorNo: 0,
        nodes: [
          GraphNode(id: 'n1', label: 'Start', x: 0, y: 0, type: 'hallway'),
          GraphNode(id: 'n2', label: 'End', x: 1, y: 1, type: 'hallway'),
        ],
        edges: [],
      );
      
      final path = AStarService.findPath(disconnectedGraph, 'n1', 'n2');
      expect(path, isEmpty);
    });
  });
}
