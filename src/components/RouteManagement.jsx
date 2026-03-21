// src/components/RouteManagement.jsx
import { useState, useEffect, useRef, useCallback } from 'react';
import { FaPlus, FaMinus, FaLayerGroup, FaTimes, FaSave, FaTrash } from 'react-icons/fa';
import { fetchFloors } from '../services/floorService';
import { getIndoorGraph, saveIndoorGraph, createNode, createEdge } from '../services/indoorGraphService';
import '../styles/indoorGraphEditor.css';



const COLORS = {
  room: '#3b82f6',
  hallway: '#f59e0b',
  stairs: '#8b5cf6',
  entrance: '#10b981',
};

const dist = (a, b) => Math.sqrt((b.x - a.x) ** 2 + (b.y - a.y) ** 2);

const RouteManagement = ({ buildingId, floorNumber }) => {
  const [currentFloorMap, setCurrentFloorMap] = useState(null);
  const [graph, setGraph] = useState({ nodes: [], edges: [] });
  const [loading, setLoading] = useState(false);

  const [viewMode, setViewMode] = useState('map');
  const [scale, setScale] = useState(1);
  const [viewBoxData, setViewBoxData] = useState({ x: 0, y: 0, width: 0, height: 0 });

  // Active tab = active mode
  const [activeTab, setActiveTab] = useState('node'); // 'node' | 'edge' | 'route'

  // Edge creation
  const [firstNodeForEdge, setFirstNodeForEdge] = useState(null);

  // Selection & inline editing
  const [selectedNodeId, setSelectedNodeId] = useState(null);
  const [editLabel, setEditLabel] = useState('');
  const [editType, setEditType] = useState('room');

  // New node being created (clicked map, need details)
  const [pendingNode, setPendingNode] = useState(null);
  const [newLabel, setNewLabel] = useState('');
  const [newType, setNewType] = useState('room');

  // Drag
  const [draggingNodeId, setDraggingNodeId] = useState(null);
  const isDragging = useRef(false);
  const dragStart = useRef(null);

  // Route testing
  const [routeStartNode, setRouteStartNode] = useState('');
  const [routeEndNode, setRouteEndNode] = useState('');
  const [computedRoute, setComputedRoute] = useState(null);
  const [routeError, setRouteError] = useState('');

  const viewportRef = useRef(null);
  const svgWrapperRef = useRef(null);
  const graphRef = useRef(graph);
  graphRef.current = graph;

  const selectedNode = graph.nodes.find(n => n.id === selectedNodeId) || null;

  // ── Auto-save helper ──────────────────────────────────
  const autoSave = useCallback(async (newGraph) => {
    if (!buildingId || floorNumber === '' || floorNumber === null || floorNumber === undefined) return;

    // Graph Validation
    const uniqueNodesMap = new Map();
    (newGraph.nodes || []).forEach(n => {
      // Bounds check: must be within the actual viewBox
      if (
        n.x >= viewBoxData.x && n.x <= viewBoxData.x + viewBoxData.width &&
        n.y >= viewBoxData.y && n.y <= viewBoxData.y + viewBoxData.height
      ) {
        if (!uniqueNodesMap.has(n.id)) {
          uniqueNodesMap.set(n.id, n);
        }
      }
    });
    const validNodes = Array.from(uniqueNodesMap.values());
    const validEdges = [];
    const nodeIds = new Set(validNodes.map(n => n.id));
    const edgeSet = new Set();

    for (const edge of (newGraph.edges || [])) {
      // Validate edge references valid node IDs that exist in the graph
      if (!nodeIds.has(edge.from) || !nodeIds.has(edge.to)) continue;

      const edgeKey1 = `${edge.from}_${edge.to}`;
      const edgeKey2 = `${edge.to}_${edge.from}`;

      // Prevent duplicate edges
      if (!edgeSet.has(edgeKey1) && !edgeSet.has(edgeKey2)) {
        edgeSet.add(edgeKey1);
        validEdges.push(edge);
      }
    }

    const validatedGraph = { nodes: validNodes, edges: validEdges };

    try {
      await saveIndoorGraph(buildingId, Number(floorNumber), {
        ...validatedGraph,
        viewBox: viewBoxData
      });
    } catch (e) {
      console.error('Auto-save failed:', e);
    }
  }, [buildingId, floorNumber, viewBoxData]);

  // ── Data loading ──────────────────────────────────────
  useEffect(() => {
    if (!buildingId || floorNumber === '' || floorNumber === null || floorNumber === undefined) {
      setGraph({ nodes: [], edges: [] });
      return;
    }
    (async () => {
      try {
        setLoading(true);
        const floors = await fetchFloors(buildingId);
        const floor = floors.find(f => f.floorNumber.toString() === floorNumber.toString());
        setCurrentFloorMap(floor || null);
        const g = await getIndoorGraph(buildingId, Number(floorNumber));

        let realVB = null;
        if (floor && floor.svgContent) {
          const parser = new DOMParser();
          const doc = parser.parseFromString(floor.svgContent, "image/svg+xml");
          const el = doc.documentElement;
          const existingVB = el.getAttribute('viewBox');
          if (existingVB) {
            const parts = existingVB.split(/[\s,]+/).map(parseFloat);
            if (parts.length >= 4) {
              realVB = { x: parts[0], y: parts[1], width: parts[2], height: parts[3] };
            }
          } else {
            const wStr = el.getAttribute('width');
            const hStr = el.getAttribute('height');
            const w = parseFloat(wStr);
            const h = parseFloat(hStr);
            if (!w || !h || isNaN(w) || isNaN(h)) {
              console.warn("Invalid default viewBox detected");
              throw new Error("SVG missing both viewBox and valid width/height attributes");
            }
            realVB = { x: 0, y: 0, width: w, height: h };
          }
          console.log("SVG viewBox:", realVB);
        }

        let finalNodes = g?.nodes || [];
        let finalEdges = g?.edges || [];
        let finalVB = g?.viewBox;

        // MIGRATION IF VIEWBOX WAS SAVED AS 800x600 BUT ACTUAL SVG IS DIFFERENT
        if (realVB && finalVB && finalVB.width === 800 && finalVB.height === 600 &&
          (realVB.width !== 800 || realVB.height !== 600)) {
          console.log("Migrating coords from 800x600 to:", realVB.width, "x", realVB.height);
          finalNodes = finalNodes.map(n => ({
            ...n,
            x: (n.x / 800) * realVB.width,
            y: (n.y / 600) * realVB.height
          }));
          finalEdges = finalEdges.map(e => {
            const fn = finalNodes.find(n => n.id === e.from);
            const tn = finalNodes.find(n => n.id === e.to);
            return { ...e, weight: fn && tn ? Math.sqrt((tn.x - fn.x) ** 2 + (tn.y - fn.y) ** 2) : e.weight };
          });
          finalVB = realVB;
          // Trigger persistent save for migration
          await saveIndoorGraph(buildingId, Number(floorNumber), {
            nodes: finalNodes, edges: finalEdges, viewBox: finalVB
          });
        } else if (realVB && !finalVB) {
          finalVB = realVB;
        }

        if (finalVB) setViewBoxData(finalVB);
        setGraph({ nodes: finalNodes, edges: finalEdges });
      } catch (e) { console.error(e); }
      finally { setLoading(false); }
    })();
  }, [buildingId, floorNumber]);

  // Setup SVG viewBox and sync with overlay
  useEffect(() => {
    if (!svgWrapperRef.current || !currentFloorMap?.svgContent || !viewBoxData.width) return;
    const el = svgWrapperRef.current.querySelector('svg');
    if (!el) return;

    if (!el.getAttribute('viewBox')) {
      el.setAttribute('viewBox', `${viewBoxData.x} ${viewBoxData.y} ${viewBoxData.width} ${viewBoxData.height}`);
    }

    el.removeAttribute('width');
    el.removeAttribute('height');
    Object.assign(el.style, { width: '100%', height: '100%', maxWidth: '100%', maxHeight: '100%' });
    el.setAttribute('preserveAspectRatio', 'xMidYMid meet');
  }, [currentFloorMap, viewBoxData]);

  // ── Coordinate helpers ────────────────────────────────
  const getSvgCoords = useCallback((e) => {
    const svg = document.getElementById('floor-svg');
    if (!svg) return null;
    const pt = svg.createSVGPoint();
    pt.x = e.clientX; pt.y = e.clientY;
    const p = pt.matrixTransform(svg.getScreenCTM().inverse());

    return { x: p.x, y: p.y };
  }, []);

  const getDynamicSnap = useCallback((val) => {
    // Snap to roughly 1% of the smallest dimension
    const step = Math.min(viewBoxData.width, viewBoxData.height) * 0.01 || 1;
    return Math.round(val / step) * step;
  }, [viewBoxData]);

  const findNodeAt = useCallback((x, y) => {
    // Adaptive threshold: 2% of the smallest dimension
    const threshold = Math.min(viewBoxData.width, viewBoxData.height) * 0.02 || 10;
    return graphRef.current.nodes.find(n => Math.abs(n.x - x) < threshold && Math.abs(n.y - y) < threshold);
  }, [viewBoxData]);

  // ── A* Routing Logic ──────────────────────────────────
  const computeRoute = () => {
    setRouteError('');
    setComputedRoute(null);

    if (!routeStartNode || !routeEndNode) {
      setRouteError('Please select both start and destination nodes.');
      return;
    }
    if (routeStartNode === routeEndNode) {
      setRouteError('Start and destination nodes must be different.');
      return;
    }

    const { nodes, edges } = graph;
    if (!nodes.length || !edges.length) {
      setRouteError('Graph is empty or has no edges.');
      return;
    }

    const startNode = nodes.find(n => n.id === routeStartNode);
    const endNode = nodes.find(n => n.id === routeEndNode);

    if (!startNode || !endNode) {
      setRouteError('Invalid start or destination node.');
      return;
    }

    // Build Adjacency List
    const adj = {};
    nodes.forEach(n => adj[n.id] = []);
    edges.forEach(e => {
      if (adj[e.from] && adj[e.to]) {
        adj[e.from].push({ node: e.to, weight: e.weight });
        adj[e.to].push({ node: e.from, weight: e.weight }); // undirected
      }
    });

    // A* implementation
    const openSet = new Set([startNode.id]);
    const cameFrom = {};
    const gScore = {};
    const fScore = {};

    nodes.forEach(n => {
      gScore[n.id] = Infinity;
      fScore[n.id] = Infinity;
    });

    gScore[startNode.id] = 0;
    fScore[startNode.id] = dist(startNode, endNode);

    while (openSet.size > 0) {
      // Find node in openSet with lowest fScore
      let currentId = null;
      let minFScore = Infinity;
      for (const id of openSet) {
        if (fScore[id] < minFScore) {
          minFScore = fScore[id];
          currentId = id;
        }
      }

      if (currentId === endNode.id) {
        // Reconstruct path
        const path = [currentId];
        let curr = currentId;
        while (cameFrom[curr]) {
          curr = cameFrom[curr];
          path.unshift(curr);
        }
        setComputedRoute(path.map(id => nodes.find(n => n.id === id)));
        return;
      }

      openSet.delete(currentId);

      const neighbors = adj[currentId] || [];
      for (const neighbor of neighbors) {
        const tentative_gScore = gScore[currentId] + neighbor.weight;

        if (tentative_gScore < gScore[neighbor.node]) {
          cameFrom[neighbor.node] = currentId;
          gScore[neighbor.node] = tentative_gScore;
          const neighborObj = nodes.find(n => n.id === neighbor.node);
          fScore[neighbor.node] = tentative_gScore + dist(neighborObj, endNode);
          if (!openSet.has(neighbor.node)) {
            openSet.add(neighbor.node);
          }
        }
      }
    }

    setRouteError('No path found between selected nodes.');
  };

  const clearRoute = () => {
    setComputedRoute(null);
    setRouteError('');
    setRouteStartNode('');
    setRouteEndNode('');
  };

  // ── Map click ─────────────────────────────────────────
  const handleMapClick = (e) => {
    if (isDragging.current) return;
    const c = getSvgCoords(e);
    if (!c) return;

    if (activeTab === 'node') {
      // Place a pending node — show creation form
      let x = getDynamicSnap(c.x);
      let y = getDynamicSnap(c.y);
      x = Math.max(viewBoxData.x, Math.min(viewBoxData.x + viewBoxData.width, x));
      y = Math.max(viewBoxData.y, Math.min(viewBoxData.y + viewBoxData.height, y));
      setPendingNode({ x, y });
      setNewLabel('');
      setNewType('room');
      setSelectedNodeId(null);
    } else if (activeTab === 'edge') {
      const hit = findNodeAt(c.x, c.y);
      if (!hit) return;
      if (!firstNodeForEdge) {
        setFirstNodeForEdge(hit);
      } else if (firstNodeForEdge.id !== hit.id) {
        const exists = graph.edges.some(e =>
          (e.from === firstNodeForEdge.id && e.to === hit.id) || (e.from === hit.id && e.to === firstNodeForEdge.id)
        );
        if (!exists) {
          const edge = createEdge(firstNodeForEdge.id, hit.id, dist(firstNodeForEdge, hit));
          const newGraph = { ...graph, edges: [...graph.edges, edge] };
          setGraph(newGraph);
          autoSave(newGraph);
        }
        setFirstNodeForEdge(null);
      }
    }
  };

  // ── Create pending node ───────────────────────────────
  const handleCreateNode = () => {
    if (!pendingNode || !newLabel.trim()) return;
    console.log("Node placed at:", pendingNode.x, pendingNode.y);
    const node = createNode(newLabel.trim(), pendingNode.x, pendingNode.y, newType);
    const newGraph = { ...graph, nodes: [...graph.nodes, node] };
    setGraph(newGraph);
    autoSave(newGraph);
    setPendingNode(null);
    setNewLabel('');
    setNewType('room');
  };

  // ── Drag ──────────────────────────────────────────────
  const handleNodeMouseDown = useCallback((e, node) => {
    if (activeTab === 'edge') return; // don't drag in edge mode
    e.stopPropagation(); e.preventDefault();
    isDragging.current = false;
    dragStart.current = { x: e.clientX, y: e.clientY };
    setDraggingNodeId(node.id);

    const onMove = (me) => {
      if (!isDragging.current) {
        if (Math.abs(me.clientX - dragStart.current.x) > 3 || Math.abs(me.clientY - dragStart.current.y) > 3) isDragging.current = true;
        else return;
      }
      const c = getSvgCoords(me);
      if (!c) return;
      setGraph(prev => ({
        ...prev,
        nodes: prev.nodes.map(n => {
          if (n.id === node.id) {
            let nx = getDynamicSnap(c.x);
            let ny = getDynamicSnap(c.y);
            nx = Math.max(viewBoxData.x, Math.min(viewBoxData.x + viewBoxData.width, nx));
            ny = Math.max(viewBoxData.y, Math.min(viewBoxData.y + viewBoxData.height, ny));
            return { ...n, x: nx, y: ny };
          }
          return n;
        })
      }));
    };

    const onUp = () => {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
      if (isDragging.current) {
        setGraph(prev => {
          const moved = prev.nodes.find(n => n.id === node.id);
          if (!moved) return prev;
          const updated = {
            ...prev,
            edges: prev.edges.map(e => {
              if (e.from === node.id || e.to === node.id) {
                const f = prev.nodes.find(n => n.id === e.from), t = prev.nodes.find(n => n.id === e.to);
                if (f && t) return { ...e, weight: dist(f, t) };
              }
              return e;
            })
          };
          autoSave(updated);
          return updated;
        });
        setTimeout(() => { isDragging.current = false; }, 50);
      } else {
        isDragging.current = false;
        // Click without drag = select node
        setSelectedNodeId(node.id);
        setEditLabel(node.label);
        setEditType(node.type);
        setPendingNode(null);
      }
      setDraggingNodeId(null);
    };

    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  }, [activeTab, getSvgCoords, autoSave, getDynamicSnap, viewBoxData]);

  // ── Node actions ──────────────────────────────────────
  const handleSaveNode = () => {
    if (!selectedNodeId || !editLabel.trim()) return;
    const newGraph = {
      ...graph,
      nodes: graph.nodes.map(n => n.id === selectedNodeId ? { ...n, label: editLabel.trim(), type: editType } : n)
    };
    setGraph(newGraph);
    autoSave(newGraph);
  };

  const handleDeleteNode = () => {
    if (!selectedNodeId) return;
    const newGraph = {
      nodes: graph.nodes.filter(n => n.id !== selectedNodeId),
      edges: graph.edges.filter(e => e.from !== selectedNodeId && e.to !== selectedNodeId)
    };
    setGraph(newGraph);
    autoSave(newGraph);
    setSelectedNodeId(null);
  };

  const handleDeleteEdge = (id) => {
    const newGraph = { ...graph, edges: graph.edges.filter(e => e.id !== id) };
    setGraph(newGraph);
    autoSave(newGraph);
  };

  // ── SVG rendering ─────────────────────────────────────
  const renderNode = (node, isGV) => {
    const color = COLORS[node.type] || '#3b82f6';
    const r = isGV ? viewBoxData.width * 0.015 : (viewBoxData.width * 0.008) / scale;
    const sw = isGV ? viewBoxData.width * 0.003 : (viewBoxData.width * 0.002) / scale;
    const fs = isGV ? viewBoxData.width * 0.025 : (viewBoxData.width * 0.015) / scale;
    const isSel = node.id === selectedNodeId;
    const isFirst = firstNodeForEdge?.id === node.id;

    return (
      <g key={node.id} style={{ pointerEvents: 'all', cursor: draggingNodeId ? 'grabbing' : 'grab' }}
        onMouseDown={(e) => handleNodeMouseDown(e, node)}>
        <circle cx={node.x} cy={node.y} r={r * 2.5} fill="transparent" />
        {(isSel || isFirst) && (
          <circle cx={node.x} cy={node.y} r={r * 2} fill="none"
            stroke={isFirst ? '#f59e0b' : color} strokeWidth={sw * 0.7}
            strokeDasharray={isFirst ? `${0.004 / scale} ${0.003 / scale}` : 'none'} opacity={0.5} />
        )}
        <circle cx={node.x} cy={node.y} r={r}
          fill={isSel ? '#fff' : color} stroke="white" strokeWidth={sw} />
        {node.label && (
          <text x={node.x + r * 1.5} y={node.y + fs * 0.35} fontSize={fs}
            fill="#1f2937" fontWeight="600" pointerEvents="none"
            style={{ textShadow: '0 0 3px #fff, 0 0 3px #fff' }}>
            {node.label}
          </text>
        )}
        <title>Node: {node.label || node.id}&#10;Coords: ({Math.round(node.x)}, {Math.round(node.y)})</title>
      </g>
    );
  };

  const renderEdge = (edge, isGV) => {
    const f = graph.nodes.find(n => n.id === edge.from);
    const t = graph.nodes.find(n => n.id === edge.to);
    if (!f || !t) return null;
    return (
      <line key={edge.id}
        x1={f.x} y1={f.y} x2={t.x} y2={t.y}
        stroke={isGV ? '#94a3b8' : '#3b82f6'}
        strokeWidth={isGV ? viewBoxData.width * 0.005 : (viewBoxData.width * 0.003) / scale}
        strokeLinecap="round" opacity={0.65}
        style={{ pointerEvents: 'stroke', cursor: 'pointer' }}
        onClick={(e) => { e.stopPropagation(); handleDeleteEdge(edge.id); }}
      />
    );
  };


  // ── Main render ───────────────────────────────────────
  return (
    <div className="ir-main-layout">
      {/* Map area */}
      <div className="ir-map-container">
        <div className="ir-map-viewer">
          <div className="ige-overlay-tl" style={{ position: 'absolute', top: '1.5rem', left: '1.5rem', zIndex: 10 }}>
            <div className="ige-view-toggle" style={{ display: 'flex', background: 'white', borderRadius: '12px', overflow: 'hidden', border: '1px solid #e1e4e8', boxShadow: '0 4px 15px rgba(0, 0, 0, 0.08)' }}>
              <button
                style={{ padding: '0.5rem 1rem', border: 'none', background: viewMode === 'map' ? '#f8f9fc' : 'white', fontWeight: viewMode === 'map' ? 700 : 500, cursor: 'pointer' }}
                onClick={() => setViewMode('map')}>Map</button>
              <button
                style={{ padding: '0.5rem 1rem', border: 'none', borderLeft: '1px solid #e1e4e8', background: viewMode === 'graph' ? '#f8f9fc' : 'white', fontWeight: viewMode === 'graph' ? 700 : 500, cursor: 'pointer' }}
                onClick={() => setViewMode('graph')}>Graph</button>
            </div>
          </div>
          {loading ? (
            <div className="loading-spinner">Loading floor map…</div>
          ) : currentFloorMap ? (
            <div
              className="ir-map-viewport"
              ref={viewportRef}
              onClick={handleMapClick}
              style={{
                transform: `scale(${scale})`,
                transformOrigin: '50% 50%',
                cursor: activeTab === 'node' || activeTab === 'edge' ? 'crosshair' : 'default',
                position: 'relative',
                background: viewMode === 'graph' ? '#f8fafc' : 'transparent'
              }}
            >
              <div style={{ position: 'relative', width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {viewMode === 'map' && (
                  currentFloorMap.svgContent ? (
                    <div className="ir-map-svg-wrapper" ref={svgWrapperRef}
                      dangerouslySetInnerHTML={{ __html: currentFloorMap.svgContent }} />
                  ) : (
                    <img src={currentFloorMap.mapUrl} alt="Floor Map"
                      style={{ maxWidth: '100%', maxHeight: '100%', pointerEvents: 'none', objectFit: 'contain' }} />
                  )
                )}
                <svg id="floor-svg" viewBox={`${viewBoxData.x} ${viewBoxData.y} ${viewBoxData.width} ${viewBoxData.height}`} preserveAspectRatio="xMidYMid meet"
                  style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }}>

                  {viewMode === 'graph' && Array.from({ length: 11 }, (_, i) => i * 0.1).map(v => (
                    <g key={v}>
                      <line x1={viewBoxData.x + v * viewBoxData.width} y1={viewBoxData.y} x2={viewBoxData.x + v * viewBoxData.width} y2={viewBoxData.y + viewBoxData.height} stroke="#e2e8f0" strokeWidth={viewBoxData.width * 0.001} />
                      <line x1={viewBoxData.x} y1={viewBoxData.y + v * viewBoxData.height} x2={viewBoxData.x + viewBoxData.width} y2={viewBoxData.y + v * viewBoxData.height} stroke="#e2e8f0" strokeWidth={viewBoxData.width * 0.001} />
                    </g>
                  ))}

                  {(activeTab !== 'route' || !computedRoute) && graph.edges.map(e => renderEdge(e, viewMode === 'graph'))}

                  {computedRoute && (
                    <polyline
                      points={computedRoute.map(n => `${n.x},${n.y}`).join(' ')}
                      stroke={viewMode === 'graph' ? '#1E88E5' : '#fbbf24'}
                      strokeWidth={viewMode === 'graph' ? viewBoxData.width * 0.006 : (viewBoxData.width * 0.006) / scale}
                      strokeLinejoin="round"
                      fill="none"
                    />
                  )}

                  {computedRoute && (
                    <circle cx={computedRoute[0].x} cy={computedRoute[0].y} r={viewMode === 'graph' ? viewBoxData.width * 0.01 : (viewBoxData.width * 0.01) / scale} fill="#10b981" />
                  )}
                  {computedRoute && (
                    <circle cx={computedRoute[computedRoute.length - 1].x} cy={computedRoute[computedRoute.length - 1].y} r={viewMode === 'graph' ? viewBoxData.width * 0.01 : (viewBoxData.width * 0.01) / scale} fill="#ef4444" />
                  )}

                  {(activeTab !== 'route' || !computedRoute)
                    ? graph.nodes.map(n => renderNode(n, viewMode === 'graph'))
                    : computedRoute.map(n => renderNode(n, viewMode === 'graph'))}
                </svg>
              </div>
            </div>
          ) : (
            <div className="ige-empty">
              <FaLayerGroup size={40} style={{ opacity: 0.15, marginBottom: '0.75rem' }} />
              <span>Select a floor with an uploaded map</span>
            </div>
          )}

          <div className="ir-zoom-controls">
            <button onClick={() => setScale(s => Math.min(s + 0.25, 5))} title="Zoom In"><FaPlus /></button>
            <button onClick={() => setScale(s => Math.max(s - 0.25, 1))} title="Zoom Out"><FaMinus /></button>
          </div>
        </div>
      </div>

      {/* Right side panel */}
      <div className="ir-side-panel">
        <div className="ir-side-header">
          <div className="ige-tab-bar" style={{ padding: 0 }}>
            <button className={`ige-tab-btn ${activeTab === 'node' ? 'active' : ''}`}
              onClick={() => { setActiveTab('node'); setFirstNodeForEdge(null); clearRoute(); }}>
              Add Node
            </button>
            <button className={`ige-tab-btn ${activeTab === 'edge' ? 'active' : ''}`}
              onClick={() => { setActiveTab('edge'); setPendingNode(null); setSelectedNodeId(null); clearRoute(); }}>
              Add Edge
            </button>
            <button className={`ige-tab-btn ${activeTab === 'route' ? 'active' : ''}`}
              onClick={() => { setActiveTab('route'); setPendingNode(null); setSelectedNodeId(null); setFirstNodeForEdge(null); }}>
              Test Route
            </button>
          </div>
        </div>

        <div className="ir-side-content" style={{ padding: '1rem', overflowY: 'auto' }}>
          <div className="ige-panel-body" style={{ padding: 0 }}>
            {/* ── NODE TAB ── */}
            {activeTab === 'node' && (
              <>
                {!pendingNode && !selectedNode && (
                  <div className="ige-hint-bar">Click on the map to place a node</div>
                )}

                {pendingNode && (
                  <div className="ige-create-form">
                    <div className="ige-form-title">New Node</div>
                    <input className="ige-form-input" placeholder="Label (e.g., 301A)"
                      value={newLabel} onChange={e => setNewLabel(e.target.value)} autoFocus />
                    <select className="ige-form-input" value={newType} onChange={e => setNewType(e.target.value)}>
                      <option value="room">Room</option>
                      <option value="hallway">Hallway</option>
                      <option value="stairs">Stairs</option>
                      <option value="entrance">Entrance</option>
                    </select>
                    <div className="ige-form-actions">
                      <button className="ige-form-btn primary" onClick={handleCreateNode} disabled={!newLabel.trim()}>
                        Create
                      </button>
                      <button className="ige-form-btn" onClick={() => setPendingNode(null)}>Cancel</button>
                    </div>
                  </div>
                )}

                <div className="ige-section-label">Nodes ({graph.nodes.length})</div>
                <div className="ige-pills-wrap">
                  {graph.nodes.map(node => (
                    <button key={node.id}
                      className={`ige-pill ${node.id === selectedNodeId ? 'active' : ''}`}
                      onClick={() => {
                        setSelectedNodeId(node.id);
                        setEditLabel(node.label);
                        setEditType(node.type);
                        setPendingNode(null);
                      }}>
                      {node.label || '—'}
                    </button>
                  ))}
                </div>

                {selectedNode && (
                  <div className="ige-edit-form">
                    <div className="ige-form-title">Edit Node</div>
                    <label className="ige-field-label">Label</label>
                    <input className="ige-form-input" value={editLabel}
                      onChange={e => setEditLabel(e.target.value)} />
                    <label className="ige-field-label">Type</label>
                    <select className="ige-form-input" value={editType} onChange={e => setEditType(e.target.value)}>
                      <option value="room">Room</option>
                      <option value="hallway">Hallway</option>
                      <option value="stairs">Stairs</option>
                      <option value="entrance">Entrance</option>
                    </select>
                    <div style={{ marginTop: '0.5rem', marginBottom: '1rem', fontSize: '0.8rem', color: '#64748b' }}>
                      Coordinates: ({Math.round(selectedNode.x)}, {Math.round(selectedNode.y)})
                    </div>
                    <div className="ige-form-actions">
                      <button className="ige-form-btn primary" onClick={handleSaveNode} disabled={!editLabel.trim()}>
                        <FaSave /> Save
                      </button>
                      <button className="ige-form-btn danger" onClick={handleDeleteNode}>
                        <FaTrash /> Delete
                      </button>
                    </div>
                  </div>
                )}
              </>
            )}

            {/* ── EDGE TAB ── */}
            {activeTab === 'edge' && (
              <>
                <div className="ige-hint-bar">
                  {firstNodeForEdge
                    ? <>From <strong>{firstNodeForEdge.label || 'node'}</strong> → click next node</>
                    : 'Click first node on the map'}
                </div>
                <div className="ige-section-label">Edges ({graph.edges.length})</div>
                <div className="ige-pills-wrap">
                  {graph.edges.map(edge => {
                    const f = graph.nodes.find(n => n.id === edge.from);
                    const t = graph.nodes.find(n => n.id === edge.to);
                    return (
                      <div key={edge.id} className="ige-edge-pill">
                        <span>{f?.label || '?'} → {t?.label || '?'}</span>
                        <button className="ige-edge-x" onClick={() => handleDeleteEdge(edge.id)}><FaTimes /></button>
                      </div>
                    );
                  })}
                </div>
              </>
            )}

            {/* ── ROUTE TAB ── */}
            {activeTab === 'route' && (
              <>
                <div className="ige-form-title">Test Route</div>
                <label className="ige-field-label">Start Node</label>
                <select className="ige-form-input" value={routeStartNode} onChange={e => setRouteStartNode(e.target.value)}>
                  <option value="">-- Select Start Node --</option>
                  {graph.nodes.map(n => (
                    <option key={n.id} value={n.id}>{n.label || n.id}</option>
                  ))}
                </select>
                <label className="ige-field-label">Destination Node</label>
                <select className="ige-form-input" value={routeEndNode} onChange={e => setRouteEndNode(e.target.value)}>
                  <option value="">-- Select Destination Node --</option>
                  {graph.nodes.map(n => (
                    <option key={n.id} value={n.id}>{n.label || n.id}</option>
                  ))}
                </select>
                {routeError && <div style={{ color: '#ef4444', fontSize: '0.85rem', marginBottom: '0.75rem', fontWeight: 500 }}>{routeError}</div>}
                <div className="ige-form-actions">
                  <button className="ige-form-btn primary" onClick={computeRoute}>View Route</button>
                  <button className="ige-form-btn" onClick={clearRoute}>Clear</button>
                </div>
                {computedRoute && (
                  <div style={{ marginTop: '1rem', padding: '0.75rem', background: '#f0fdf4', borderRadius: '4px', fontSize: '0.875rem' }}>
                    <strong style={{ color: '#166534', display: 'block', marginBottom: '0.25rem' }}>Route Found!</strong>
                    <span style={{ color: '#15803d' }}>
                      {computedRoute.map(n => n.label || n.id).join(' → ')}
                    </span>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default RouteManagement;
