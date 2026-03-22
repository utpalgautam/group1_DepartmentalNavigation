import 'dart:math';
import '../models/floor_model.dart';

class AStarNode {
  final GraphNode node;
  double g; // Cost from start to this node
  double h; // Heuristic (estimated cost to destination)
  AStarNode? parent;

  AStarNode(this.node, {this.g = 0, this.h = 0, this.parent});

  double get f => g + h;
}

class AStarService {
  /// Finds the shortest path between startNodeId and endNodeId in the given graph.
  static List<GraphNode> findPath(IndoorGraph graph, String startLabel, String endLabel) {
    GraphNode? startNode;
    GraphNode? endNode;

    for (var node in graph.nodes) {
      if (node.label == startLabel || node.id == startLabel) startNode = node;
      if (node.label == endLabel || node.id == endLabel) endNode = node;
    }

    if (startNode == null || endNode == null) {
      return [];
    }

    List<AStarNode> openList = [];
    List<AStarNode> closedList = [];

    openList.add(AStarNode(startNode, h: _calculateDistance(startNode, endNode)));

    while (openList.isNotEmpty) {
      // Get node with lowest f cost
      AStarNode current = openList.reduce((a, b) => a.f < b.f ? a : b);

      if (current.node.id == endNode.id) {
        return _reconstructPath(current);
      }

      openList.remove(current);
      closedList.add(current);

      // Explore neighbors
      for (var edge in graph.edges) {
        String? neighborId;
        if (edge.from == current.node.id) {
          neighborId = edge.to;
        } else if (edge.to == current.node.id) neighborId = edge.from;

        if (neighborId != null) {
          if (closedList.any((n) => n.node.id == neighborId)) continue;

          GraphNode? neighborNode;
          try {
            neighborNode = graph.nodes.firstWhere((n) => n.id == neighborId);
          } catch (_) {
            neighborNode = null;
          }

          if (neighborNode == null) continue;
          double gScore = current.g + edge.weight;

          AStarNode? openNode;
          try {
            openNode = openList.firstWhere((n) => n.node.id == neighborId);
          } catch (_) {
            openNode = null;
          }

          if (openNode == null) {
            openList.add(AStarNode(
              neighborNode,
              g: gScore,
              h: _calculateDistance(neighborNode, endNode),
              parent: current,
            ));
          } else if (gScore < openNode.g) {
            openNode.g = gScore;
            openNode.parent = current;
          }
        }
      }
    }

    return []; // No path found
  }

  static double _calculateDistance(GraphNode a, GraphNode b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  static List<GraphNode> _reconstructPath(AStarNode? endNode) {
    List<GraphNode> path = [];
    AStarNode? current = endNode;
    while (current != null) {
      path.add(current.node);
      current = current.parent;
    }
    return path.reversed.toList();
  }
}
