# Indoor Graph Editor - API Reference

## Service API: `indoorGraphService.js`

### `getIndoorGraph(buildingId, floorNumber)`

Fetches an existing graph from Firebase.

**Parameters:**
- `buildingId` (string): Building identifier
- `floorNumber` (number): Floor number (0-based)

**Returns:**
- Promise resolving to graph object or null if not found

**Graph Object Structure:**
```javascript
{
  id: string,                    // Document ID
  buildingId: string,
  floorNo: number,
  nodes: [
    { id: string, label: string, x: number, y: number, type: string },
    ...
  ],
  edges: [
    { id: string, from: string, to: string, weight: number },
    ...
  ],
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Example:**
```javascript
import { getIndoorGraph } from '../services/indoorGraphService';

const graph = await getIndoorGraph('building1', 2);
if (graph) {
  console.log(`Found ${graph.nodes.length} nodes, ${graph.edges.length} edges`);
}
```

**Error Handling:**
```javascript
try {
  const graph = await getIndoorGraph('building1', 2);
} catch (error) {
  console.error("Error fetching graph: ", error);
  // Handle error appropriately
}
```

---

### `saveIndoorGraph(buildingId, floorNumber, graphData)`

Saves or updates a graph in Firebase.

**Parameters:**
- `buildingId` (string): Building identifier
- `floorNumber` (number): Floor number
- `graphData` (object): `{ nodes: [], edges: [] }`

**Returns:**
- Promise resolving to saved graph object with ID

**Saved Document Structure:**
```javascript
{
  buildingId: string,
  floorNo: number,
  nodes: Node[],
  edges: Edge[],
  createdAt: Timestamp,      // Set on first save
  updatedAt: Timestamp        // Updated on each save
}
```

**Example:**
```javascript
import { saveIndoorGraph } from '../services/indoorGraphService';

const graphData = {
  nodes: [
    { id: 'n1', label: 'Room 101', x: 0.25, y: 0.30, type: 'room' },
    { id: 'n2', label: 'Hallway', x: 0.50, y: 0.50, type: 'hallway' }
  ],
  edges: [
    { id: 'e1', from: 'n1', to: 'n2', weight: 1 }
  ]
};

await saveIndoorGraph('building1', 2, graphData);
console.log('Graph saved successfully');
```

**Important Notes:**
- Uses `setDoc(..., { merge: true })` for upsert behavior
- `createdAt` is only set on first save
- `updatedAt` is updated on every save
- Overwrites existing graph data for same building/floor

---

### `createNode(label, x, y, type)`

Creates a node object with auto-generated ID and normalized coordinates.

**Parameters:**
- `label` (string): Display name (e.g., "Room 101")
- `x` (number): Normalized X coordinate (0-1)
- `y` (number): Normalized Y coordinate (0-1)
- `type` (string): Node type ("room", "hallway", "stairs", "entrance")

**Returns:**
- Node object ready to add to graph

**Node Object Structure:**
```javascript
{
  id: string,       // Auto-generated unique ID
  label: string,    // Display name
  x: number,        // Normalized to 3 decimals
  y: number,        // Normalized to 3 decimals
  type: string      // One of: "room", "hallway", "stairs", "entrance"
}
```

**Example:**
```javascript
import { createNode } from '../services/indoorGraphService';

const newNode = createNode('Room 201', 0.4, 0.6, 'room');
console.log(newNode);
// Output: { id: 'node_1234567890_abc123', label: 'Room 201', x: 0.4, y: 0.6, type: 'room' }
```

**Coordinate Examples:**
```javascript
// SVG coordinate (100, 150) on 800x600 map
const x = 100 / 800;  // 0.125
const y = 150 / 600;  // 0.25
const node = createNode('Office', x, y, 'room');
// Stores: { x: 0.125, y: 0.25 } - precise across all screen sizes
```

---

### `createEdge(fromNodeId, toNodeId, weight)`

Creates an edge object with auto-generated ID.

**Parameters:**
- `fromNodeId` (string): Source node ID
- `toNodeId` (string): Target node ID
- `weight` (number, optional): Edge weight for pathfinding (default: 1)

**Returns:**
- Edge object ready to add to graph

**Edge Object Structure:**
```javascript
{
  id: string,       // Auto-generated unique ID
  from: string,     // Source node ID
  to: string,       // Target node ID
  weight: number    // Pathfinding weight
}
```

**Example:**
```javascript
import { createEdge } from '../services/indoorGraphService';

const edge = createEdge('node_111_abc', 'node_222_def', 1.0);
console.log(edge);
// Output: { id: 'edge_1234567890_xyz789', from: 'node_111_abc', to: 'node_222_def', weight: 1.0 }
```

**Weighted Edges:**
```javascript
// Regular hallway (weight 1)
const hallway = createEdge(nodeA, nodeB, 1);

// Longer distance (weight 2)
const longCorridor = createEdge(nodeA, nodeC, 2);

// Stairs/elevator (weight 3, slower traversal)
const stairs = createEdge(floor1Node, floor2Node, 3);
```

---

## Component API: `IndoorGraphEditor`

### Props

```typescript
interface IndoorGraphEditorProps {
  buildingId: string      // Building ID to edit graphs for
  floorNumber: string     // Floor number as string ("0", "1", etc.)
}
```

**Example Usage:**
```jsx
import IndoorGraphEditor from './IndoorGraphEditor';

<IndoorGraphEditor 
  buildingId="building123" 
  floorNumber="2" 
/>
```

### State Variables

```javascript
// Data
const [graph, setGraph] = useState({ nodes: [], edges: [] });
const [currentFloorMap, setCurrentFloorMap] = useState(null);

// UI Mode
const [activeMode, setActiveMode] = useState('node');  // 'node' or 'edge'
const [selectedNode, setSelectedNode] = useState(null);
const [showNodeModal, setShowNodeModal] = useState(false);

// Edge Creation
const [firstNodeForEdge, setFirstNodeForEdge] = useState(null);
const [secondNodeForEdge, setSecondNodeForEdge] = useState(null);

// UI
const [scale, setScale] = useState(1);
const [loading, setLoading] = useState(false);
const [isSaving, setIsSaving] = useState(false);
```

### Ref Variables

```javascript
const viewportRef = useRef(null);      // SVG viewport for coordinate mapping
const svgWrapperRef = useRef(null);    // SVG wrapper for setup
```

### Event Handlers

#### `handleMapClick(e)`
Triggered when user clicks on the map.
- **Mode: "node"** → Opens node creation modal
- **Mode: "edge"** → Selects/connects nodes

#### `handleSaveNode()`
Called when user confirms node creation in modal.
- Validates label not empty
- Creates node with normalized coordinates
- Adds to graph
- Closes modal

#### `handleDeleteNode(nodeId)`
Called when user clicks delete on a node.
- Warns user about edge deletion
- Removes node and connected edges
- Updates graph state

#### `handleSaveGraph()`
Called when user clicks "Save Graph" button.
- Sets loading state
- Calls `saveIndoorGraph()`
- Shows success/error message
- Updates UI

#### `handleUndo()`
Called when user clicks "Undo" button.
- Removes last added node
- Removes associated edges
- Updates graph state

---

## Coordinate Mapping

### Viewport to Normalized Coordinates

```javascript
// Get viewport dimensions
const rect = viewportRef.current.getBoundingClientRect();

// Calculate click position in normalized coordinates
const x = (e.clientX - rect.left) / rect.width;
const y = (e.clientY - rect.top) / rect.height;

// Round to 3 decimal places
const normalizedX = parseFloat(x.toFixed(3));
const normalizedY = parseFloat(y.toFixed(3));
```

### Normalized to SVG Rendering

```javascript
// SVG with viewBox="0 0 1 1" automatically scales coordinates
<svg viewBox="0 0 1 1" preserveAspectRatio="none" style={{ width: '100%', height: '100%' }}>
  {graph.nodes.map(node => (
    <circle cx={node.x} cy={node.y} r={0.006} fill="blue" />
  ))}
</svg>

// Node at (0.5, 0.5) always appears in center regardless of viewport size
```

---

## Color Coding

Node types use consistent colors for visual identification:

```javascript
const colors = {
  room: '#3b82f6',      // Blue
  hallway: '#f59e0b',   // Amber/Orange
  stairs: '#8b5cf6',    // Purple
  entrance: '#10b981'   // Green
};
```

Used in CSS classes: `.ige-type-badge.room`, `.ige-type-badge.hallway`, etc.

---

## Firebase Collection Structure

### Collection: `indoorGraphs`

**Document ID Pattern:** `{buildingId}_floor_{floorNumber}`

**Example Doc Path:** `indoorGraphs/building1_floor_2`

**Field Types:**
```javascript
{
  buildingId: string,           // Indexed for queries
  floorNo: number,              // Floor number
  nodes: Array<Node>,           // Array of node objects
  edges: Array<Edge>,           // Array of edge objects
  createdAt: Timestamp,         // Firebase server timestamp
  updatedAt: Timestamp          // Firebase server timestamp
}
```

**Indexes (if needed):**
```
Collection: indoorGraphs
- buildingId (Ascending)
- floorNo (Ascending)
- createdAt (Descending)
```

---

## Error Codes & Handling

```javascript
// Example error handling
try {
  const graph = await getIndoorGraph(buildingId, floorNo);
  if (!graph) {
    console.warn('No graph found, creating new one');
    // Initialize empty graph
  }
} catch (error) {
  if (error.code === 'permission-denied') {
    console.error('Firebase permission denied');
    alert('Access denied: Check Firebase security rules');
  } else if (error.code === 'not-found') {
    console.error('Graph not found');
  } else {
    console.error('Unknown error:', error);
  }
}
```

---

## Performance Considerations

- **Large Graphs:** > 1000 nodes may cause rendering slowdown
- **Coordinate Precision:** 3 decimals sufficient for any size building
- **Edge Rendering:** O(n) performance where n = number of edges
- **Node Rendering:** O(n) performance with color-coding
- **Save Operation:** Asynchronous - doesn't block UI

---

## Security Notes

- Requires Firebase authentication
- Graph data is stored per `buildingId` + `floorNo`
- Recommend Firestore security rules:
```
match /indoorGraphs/{document=**} {
  allow read, write: if request.auth != null;
}
```

- Consider row-level security for multi-tenant deployments

---

## Version History

- **v1.0** - Initial release
  - Basic node/edge CRUD
  - Firebase integration
  - Normalized coordinate system
  - Modal UI for node creation
  - Zoom controls
  - Undo functionality
