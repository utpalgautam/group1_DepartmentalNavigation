import 'package:flutter_test/flutter_test.dart';
import 'package:dept_nav_app/models/floor_model.dart';
import 'package:dept_nav_app/services/astar_service.dart';

void main() {
  test('AStar should not crash when an edge points to a missing node', () {
    final brokenGraph = IndoorGraph(
      buildingId: 'b1',
      floorNo: 0,
      nodes: [
        GraphNode(id: 'n1', label: 'Start', x: 0, y: 0, type: 'hallway'),
        GraphNode(id: 'n2', label: 'End', x: 1, y: 1, type: 'hallway'),
      ],
      edges: [
        GraphEdge(from: 'n1', to: 'NON_EXISTENT', weight: 1.0),
        GraphEdge(from: 'n1', to: 'n2', weight: 2.0),
      ],
    );
    
    // This might throw an exception if findPath is not robust
    final path = AStarService.findPath(brokenGraph, 'n1', 'n2');
    expect(path, isNotEmpty);
    expect(path.last.id, 'n2');
  });
}
