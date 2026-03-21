# Indoor Graph Editor Implementation

## Overview

The Indoor Graph Editor is a new feature that replaces the Interactive Route system with a graph-based indoor navigation system. It allows administrators to:

- **Add nodes** on SVG floor maps (rooms, hallways, stairs, entrances)
- **Connect nodes with edges** to define navigation paths
- **Label nodes** with custom names and types
- **Save graphs** to Firebase with proper coordinate normalization

## Architecture

### Components

#### [IndoorGraphEditor.jsx](../components/IndoorGraphEditor.jsx)
Main component that manages the graph editing interface. Features:
- Dual-mode interface: "Add Node" and "Add Edge" modes
- Modal dialog for node creation with type selection
- Real-time graph visualization on SVG floor maps
- Node markers with color-coded types
- Edge rendering with click-to-delete functionality
- Zoom controls and map navigation
- Undo functionality
- Save to Firebase with timestamp tracking

**Key State:**
- `graph`: `{ nodes: [], edges: [] }`
- `activeMode`: "node" | "edge"
- `selectedNode`: Currently selected node for edge creation
- `showNodeModal`: Controls node creation dialog visibility

#### [indoorGraphService.js](../services/indoorGraphService.js)
Firebase integration layer providing graph operations:

**Exported Functions:**
- `getIndoorGraph(buildingId, floorNumber)` - Fetch graph from Firebase
- `saveIndoorGraph(buildingId, floorNumber, graphData)` - Save/update graph
- `createNode(label, x, y, type)` - Create node object with normalized coordinates
- `createEdge(fromNodeId, toNodeId, weight)` - Create edge object

**Firebase Collection Structure:**
```
indoorGraphs/
  {buildingId}_floor_{floorNumber}/
    {
      buildingId: string,
      floorNo: number,
      nodes: [{id, label, x, y, type}, ...],
      edges: [{id, from, to, weight}, ...],
      createdAt: timestamp,
      updatedAt: timestamp
    }
```

### Modified Components

#### [RouteManagement.jsx](../components/RouteManagement.jsx)
Updated to include both:
- **New Graph Editor** (default): Full graph editing interface
- **Legacy Routes**: Original POI + Route system (accessed via toggle button)

Mode toggle buttons:
- "Switch to Routes" button in Graph Editor mode
- "→ Graph Editor" button in Routes mode (3rd tab in tabs-toggle)

## Data Model

### Node
```javascript
{
  id: string,           // Unique identifier (auto-generated)
  label: string,        // Display name (e.g., "Room 101")
  x: number,            // Normalized X coordinate (0-1)
  y: number,            // Normalized Y coordinate (0-1)
  type: "room" | "hallway" | "stairs" | "entrance"
}
```

### Edge
```javascript
{
  id: string,           // Unique identifier (auto-generated)
  from: string,         // Source node ID
  to: string,           // Target node ID
  weight: number        // Edge weight (default: 1)
}
```

### Graph Document
```javascript
{
  buildingId: string,
  floorNo: number,
  nodes: Node[],
  edges: Edge[],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

## Coordinate System

**Critical Requirement:** All node coordinates are stored as **normalized values between 0 and 1** relative to the SVG viewBox.

**Calculation:**
```javascript
normalizedX = clickX / viewportWidth
normalizedY = clickY / viewportHeight
```

**Advantages:**
- ✅ Coordinates remain valid across all screen sizes
- ✅ Responsive rendering on different resolutions
- ✅ Easy to export/import between systems
- ✅ SVG native coordinate system (viewBox: "0 0 1 1")

**Rendering:**
When rendering nodes on SVG overlay, coordinates map directly to the 0-1 coordinate system:
```jsx
<svg viewBox="0 0 1 1" preserveAspectRatio="none" style={{ width: '100%', height: '100%' }}>
  {graph.nodes.map(node => (
    <circle cx={node.x} cy={node.y} r={0.006} fill="#3b82f6" />
  ))}
</svg>
```

## Usage Flow

### Adding Nodes
1. Click "Add Node" tab
2. Click on the map to place a node
3. Modal appears asking for:
   - Node Label (text input)
   - Node Type (dropdown: room, hallway, stairs, entrance)
4. Click "Add Node" button
5. Node appears on map with color-coded badge

### Adding Edges
1. Click "Add Edge" tab
2. Click on first node
3. Click on second node
4. Edge is automatically created and rendered as a line
5. Click edge line to delete it

### Saving
1. Edit nodes and edges as needed
2. Click "Save Graph" button
3. Data is saved to Firebase with updatedAt timestamp
4. Success message confirms save

### Loading
When building + floor is selected:
1. `getIndoorGraph()` fetches existing graph from Firebase
2. Nodes are rendered with color-coded type badges
3. Edges are rendered as connecting lines
4. Full editing interface is available

## Color Coding

Node types are color-coded for easy identification:

| Type | Color | Hex |
|------|-------|-----|
| Room | Blue | #3b82f6 |
| Hallway | Amber | #f59e0b |
| Stairs | Purple | #8b5cf6 |
| Entrance | Green | #10b981 |

## Styling

### CSS File
[indoorGraphEditor.css](../styles/indoorGraphEditor.css)

**Key Classes:**
- `.indoor-graph-editor` - Main flex container
- `.ige-map-container` - Map display area
- `.ige-side-panel` - Control sidebar (320px fixed width)
- `.ige-modal-overlay` - Modal backdrop
- `.ige-mode-toggle` - Tab buttons for mode selection

**Responsive Design:**
- Desktop: Side-by-side layout (map + panel)
- Mobile (< 1200px): Stacked layout (map full-width, panel below at 250px height)

## Integration Points

### Input Sources
- User clicks on SVG canvas (map)
- Form inputs (node label, type selection)
- Button clicks (save, delete, undo, zoom)

### Output Targets
- Firebase `indoorGraphs` collection (graph data)
- Browser state (UI updates)
- SVG rendering (node/edge visualization)

### Dependencies
```
react: ^18
react-icons: ^4 (FaPlus, FaMinus, etc.)
firebase: ^9+
```

## Error Handling

- **Duplicate edges**: Prevented by checking existing edges before creation
- **Orphaned edges**: Automatically removed when nodes are deleted
- **Firebase errors**: Logged to console with user-facing alert
- **Invalid coordinates**: Clamped to 0-1 range

## Future Enhancements

- [ ] Edge weight editor
- [ ] Bidirectional edge toggle
- [ ] Import/Export graph as JSON
- [ ] Graph validation and analysis
- [ ] Pathfinding visualization
- [ ] Bulk node operations
- [ ] Grid snap-to options
- [ ] Node/edge styling customization

## Development Notes

### Coordinate Normalization
The normalized coordinate system is enforced at these points:
1. **On input**: `normalizedX = parseFloat((clickX / width).toFixed(3))`
2. **On render**: SVG viewBox="0 0 1 1" with preserveAspectRatio="none"
3. **On save**: Stored directly in Firebase
4. **On load**: Read as-is and rendered on 0-1 coordinate system

### Node/Edge ID Generation
```javascript
id = `node_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
```

Ensures globally unique IDs across concurrent editor sessions.

### Edge Selection for Deletion
Edges are clicked by striking through the line with hover opacity effect:
```jsx
<g className="edge-line-group" style={{ pointerEvents: 'stroke' }}>
  <line stroke-width="4px" opacity="0" onMouseOver={opacity = 0.3} />
</g>
```

This makes thin edges easier to click without expanding the hitbox visually.
