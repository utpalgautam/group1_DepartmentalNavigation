import 'package:flutter_test/flutter_test.dart';
import 'package:dept_nav_app/models/floor_model.dart';

void main() {
  group('IndoorGraph.fromFirestore', () {
    test('should parse nodes and edges from Map format', () {
      final data = {
        'buildingId': 'b1',
        'floorNo': 0,
        'nodes': {
          'n1': {'id': 'n1', 'label': 'Start', 'x': 0.0, 'y': 0.0, 'type': 'hallway'},
          'n2': {'id': 'n2', 'label': 'End', 'x': 1.0, 'y': 1.0, 'type': 'hallway'},
        },
        'edges': {
          'e1': {'from': 'n1', 'to': 'n2', 'weight': 1.0},
        },
      };

      final graph = IndoorGraph.fromFirestore(data);

      expect(graph.nodes.length, 2);
      expect(graph.edges.length, 1);
      expect(graph.nodes.any((n) => n.id == 'n1'), true);
      expect(graph.nodes.any((n) => n.id == 'n2'), true);
      expect(graph.edges.first.from, 'n1');
      expect(graph.edges.first.to, 'n2');
    });

    test('should parse nodes and edges from List format', () {
      final data = {
        'buildingId': 'b1',
        'floorNo': 0,
        'nodes': [
          {'id': 'n1', 'label': 'Start', 'x': 0.0, 'y': 0.0, 'type': 'hallway'},
          {'id': 'n2', 'label': 'End', 'x': 1.0, 'y': 1.0, 'type': 'hallway'},
        ],
        'edges': [
          {'from': 'n1', 'to': 'n2', 'weight': 1.0},
        ],
      };

      final graph = IndoorGraph.fromFirestore(data);

      expect(graph.nodes.length, 2);
      expect(graph.edges.length, 1);
    });
  });
}
