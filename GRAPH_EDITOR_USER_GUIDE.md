# Indoor Graph Editor - Quick Reference

## 🎯 What is the Indoor Graph Editor?

A new tool for creating indoor navigation maps by placing nodes (locations) and connecting them with edges (paths).

## 📍 Node Types

| Type | Use Case | Color |
|------|----------|-------|
| **Room** | Classrooms, offices, labs | 🔵 Blue |
| **Hallway** | Corridors, walkways | 🟠 Orange |
| **Stairs** | Stairwell, elevator | 🟣 Purple |
| **Entrance** | Main entry, exit, portal | 🟢 Green |

## ⚡ Quick Start (5 Minutes)

### Step 1: Add Nodes
1. Go to **Interactive Route** page
2. Select **Building** and **Floor**
3. Click **Add Node** tab in the right panel
4. Click anywhere on the map to place a node
5. A dialog appears:
   - Enter node name (e.g., "Room 101", "Main Stairs")
   - Select node type from dropdown
   - Click "Add Node" to confirm
6. Node appears on map with colored badge
7. Repeat for all locations

### Step 2: Connect with Edges
1. Click **Add Edge** tab in the right panel
2. Click on the first node (the start point)
3. Click on the second node (the target point)
4. An edge line appears connecting them
5. Repeat to create all connections

### Step 3: Review & Save
1. Check the right panel for list of nodes and edges
2. Review the map layout
3. Delete any mistakes:
   - Select node → click "Delete" button
   - Click edge line to delete it
4. Click **Save Graph** button (blue)
5. Wait for success message

## 🎮 Controls

### Map Navigation
- **Zoom In:** Click `+` button (bottom right)
- **Zoom Out:** Click `-` button (bottom right)
- **Click Map:** Place node (Add Node mode) or select node (Add Edge mode)
- **Click Edge:** Delete edge

### Tools
- **Undo:** Click "Undo" button to remove last item
- **Clear All:** (Routes mode) Clear all placed points
- **Save Graph:** Persist graph to database

## ✏️ Editing Operations

### Add Node
1. Click **Add Node** tab
2. Click on map
3. Fill in dialog
4. Click "Add Node"

### Delete Node
1. Click on the node in the Add Node view
2. Click "Delete" button
3. Confirm deletion (edges will auto-remove)

### Add Edge
1. Click **Add Edge** tab
2. Click first node
3. Click second node
4. Edge appears automatically

### Delete Edge
1. Click on the edge line (hover shows highlight)
2. Edge disappears

### Undo
1. Click "Undo" button
2. Last added item (node or edge) is removed

## 💾 Saving

- **Save Graph:** Click blue "Save Graph" button
- **Location:** Data saved to Firebase database
- **Success:** Message appears when saved
- **Not Saving?** Check:
  - Internet connection active
  - Firebase permissions configured
  - Building/Floor properly selected

## 🔄 Switch Between Editors

- **Graph Mode → Route Mode:** "Switch to Routes" button, or use "→ Graph Editor" tab (3rd tab off)
- **Route Mode → Graph Mode:** "→ Graph Editor" button in 3rd tab
- **Keep Both:** Nodes and POIs are separate systems

## ❓ Common Tasks

### I want to edit an existing building
1. Select the building and floor
2. Graph loads automatically with existing nodes/edges
3. Make changes as needed
4. Click "Save Graph"

### I want to delete all nodes on a floor
1. Use "Undo" repeatedly, OR
2. Delete nodes one by one
3. Save Graph when done

### I made a mistake, can I undo?
1. Click "Undo" button (limited to adding nodes/edges)
2. For larger changes, reload page and start over

### Node won't stay where I click?
1. Use **crosshair cursor** to aim precisely
2. Zoom in for better accuracy
3. Node coordinates are stored relative to map size

### Edge won't connect my nodes?
1. Click first node (should highlight)
2. Then click second node
3. Edge should appear automatically
4. If not, check nodes are placed first

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| Nodes disappearing | Reload page - graph reloads from database |
| Can't place nodes | Make sure "Add Node" tab is selected, not "Add Edge" |
| Edge won't delete | Click directly on the edge line (thin line may need precision) |
| Save not working | Check internet, refresh page, try again |
| Portal too slow | Zoom out, reduce number of nodes visible |

## 📊 Database Info

- **Storage:** Firebase Cloud Firestore
- **Location:** `indoorGraphs` collection
- **Document ID:** `{buildingId}_floor_{floorNumber}`
- **Data:** Normalized coordinates (0-1) + node/edge data

## 💡 Tips & Best Practices

✅ **Do:**
- Use clear, consistent naming (e.g., "Room 101", "Floor 2 Hallway")
- Place nodes at actual location centers
- Connect adjacent spaces with edges
- Save frequently while editing
- Test pathfinding after major edits

❌ **Don't:**
- Place nodes too close together (may be hard to click)
- Create long chains without intermediate nodes
- Forget to save before closing
- Edit outdated floor maps
- Mix coordinate systems (use normalized 0-1 always)

## 📱 Mobile Users

The editor works on tablets/phones but is optimized for desktop:
- Less screen space for map
- Touch aiming may be less precise
- Use zoom controls liberally
- Consider larger nodes for touch targets

## 🆘 Need Help?

1. Check the **Undo** button to revert mistakes
2. Review the map before saving
3. Contact admin with building/floor details
4. Check Firebase console for error logs
