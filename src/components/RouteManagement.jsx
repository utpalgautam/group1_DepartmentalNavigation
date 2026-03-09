import { useState, useEffect, useRef } from 'react';
import { FaMapMarkerAlt, FaRoute, FaTrash, FaUndo, FaSave, FaLayerGroup, FaBuilding, FaPlus, FaMinus } from 'react-icons/fa';
import { fetchFloors } from '../services/floorService';
import { fetchLocationsByFloor } from '../services/locationService';
import { addRoute, getRoutesByFloor, deleteRoute } from '../services/routeService';
import { addPOI, getPOIsByFloor, deletePOI } from '../services/poiService';

const RouteManagement = ({ buildingId, floorNumber }) => {
  // Data state
  const [currentFloorMap, setCurrentFloorMap] = useState(null);
  const [existingRoutes, setExistingRoutes] = useState([]);
  const [pois, setPois] = useState([]);

  // UI state
  const [activeTab, setActiveTab] = useState('route'); // 'route' or 'poi'
  const [fromLocationId, setFromLocationId] = useState(''); // This will be the POI name
  const [toLocationId, setToLocationId] = useState(''); // This will be the POI name
  const [poiName, setPoiName] = useState('');
  const [points, setPoints] = useState([]); // Middle points (waypoints)
  const [scale, setScale] = useState(1);
  const [mapDimensions, setMapDimensions] = useState({ width: 0, height: 0, ratio: 1 });

  const [isSaving, setIsSaving] = useState(false);
  const [loading, setLoading] = useState(false);

  const viewportRef = useRef(null);
  const svgWrapperRef = useRef(null);

  // When building/floor changes: Fetch Map, Locations, Routes, and POIs
  useEffect(() => {
    if (!buildingId || floorNumber === '') return;

    const loadFloorData = async () => {
      try {
        setLoading(true);
        const floorsData = await fetchFloors(buildingId);
        const floor = floorsData.find(f => f.floorNumber.toString() === floorNumber);
        setCurrentFloorMap(floor || null);
        setPois(floor?.pois || []);

        const routeData = await getRoutesByFloor(buildingId, floorNumber);
        setExistingRoutes(routeData);

        // Reset creation state
        setPoints([]);
        setFromLocationId('');
        setToLocationId('');
        setPoiName('');
        setScale(1);
      } catch (err) {
        console.error("Failed to load floor data", err);
      } finally {
        setLoading(false);
      }
    };
    loadFloorData();
  }, [buildingId, floorNumber]);

  // Handle image load to get natural dimensions
  const handleImageLoad = (e) => {
    const { naturalWidth, naturalHeight } = e.target;
    setMapDimensions({
      width: naturalWidth,
      height: naturalHeight,
      ratio: naturalWidth / naturalHeight
    });
  };

  // After SVG content is injected, add viewBox so it scales properly
  useEffect(() => {
    if (!svgWrapperRef.current || !currentFloorMap?.svgContent) return;
    const svgEl = svgWrapperRef.current.querySelector('svg');
    if (!svgEl) return;

    // Use the actual bounding box of the SVG content for accurate centering
    try {
      const bbox = svgEl.getBBox();
      // Add some padding around the content
      const padding = 10;
      svgEl.setAttribute('viewBox', `${bbox.x - padding} ${bbox.y - padding} ${bbox.width + padding * 2} ${bbox.height + padding * 2}`);
    } catch (e) {
      // Fallback: use width/height attributes if getBBox fails
      if (!svgEl.getAttribute('viewBox')) {
        const w = svgEl.getAttribute('width') || 800;
        const h = svgEl.getAttribute('height') || 600;
        svgEl.setAttribute('viewBox', `0 0 ${parseFloat(w)} ${parseFloat(h)}`);
      }
    }
    // Remove fixed width/height so it scales to fit the container
    svgEl.removeAttribute('width');
    svgEl.removeAttribute('height');
    svgEl.style.width = '100%';
    svgEl.style.height = '100%';
    svgEl.style.maxWidth = '100%';
    svgEl.style.maxHeight = '100%';
    // Center the SVG content within the viewport
    svgEl.setAttribute('preserveAspectRatio', 'xMidYMid meet');
  }, [currentFloorMap]);

  // Derived anchors
  const startAnchor = pois.find(p => p.name === fromLocationId);
  const endAnchor = pois.find(p => p.name === toLocationId);

  // Full route points: [Start, ...Waypoints, End]
  const fullRoutePoints = [];
  if (startAnchor) fullRoutePoints.push({ x: startAnchor.x, y: startAnchor.y });
  fullRoutePoints.push(...points);
  if (endAnchor) fullRoutePoints.push({ x: endAnchor.x, y: endAnchor.y });

  const handleMapClick = (e) => {
    if (!currentFloorMap || !viewportRef.current) return;

    const rect = viewportRef.current.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;

    const newPoint = { x: parseFloat(x.toFixed(2)), y: parseFloat(y.toFixed(2)) };

    if (activeTab === 'poi') {
      setPoints([newPoint]);
    } else {
      if (!startAnchor || !endAnchor) {
        alert("Please select both Start Point and Destination POIs first.");
        return;
      }
      setPoints([...points, newPoint]);
    }
  };

  const handleZoom = (delta) => {
    setScale(prev => Math.min(Math.max(prev + delta, 1), 5));
  };

  const handleUndoPoint = () => {
    setPoints(points.slice(0, -1));
  };

  const handleClearPoints = () => {
    setPoints([]);
    setFromLocationId('');
    setToLocationId('');
  };

  const handleSaveRoute = async () => {
    if (!fromLocationId || !toLocationId) {
      alert("Please select both start and destination POIs.");
      return;
    }
    if (fromLocationId === toLocationId) {
      alert("Start and destination cannot be the same.");
      return;
    }

    try {
      setIsSaving(true);
      const routeData = {
        buildingId,
        floorNumber: Number(floorNumber),
        fromLocation: fromLocationId,
        toLocation: toLocationId,
        points: fullRoutePoints,
        distanceMeters: calculateEstimatedDistance(fullRoutePoints)
      };

      await addRoute(routeData);
      const updatedRoutes = await getRoutesByFloor(buildingId, floorNumber);
      setExistingRoutes(updatedRoutes);

      setPoints([]);
      setFromLocationId('');
      setToLocationId('');
      alert("Route saved successfully!");
    } catch (err) {
      console.error("Error saving route", err);
      alert("Failed to save route.");
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteRoute = async (id) => {
    if (!window.confirm("Delete this route?")) return;
    try {
      await deleteRoute(id);
      setExistingRoutes(existingRoutes.filter(r => r.id !== id));
    } catch (err) {
      alert("Failed to delete route.");
    }
  };

  const handleSavePOI = async () => {
    if (!poiName) {
      alert("Please enter a POI name.");
      return;
    }
    if (points.length === 0) {
      alert("Please mark a point on the map for the POI.");
      return;
    }

    try {
      setIsSaving(true);
      const poiPoint = points[0];
      const poiObj = {
        name: poiName,
        x: poiPoint.x,
        y: poiPoint.y
      };

      await addPOI(buildingId, Number(floorNumber), poiObj);
      const updatedPois = await getPOIsByFloor(buildingId, floorNumber);
      setPois(updatedPois);

      setPoiName('');
      setPoints([]);
      alert("POI saved successfully!");
    } catch (err) {
      console.error("Error saving POI", err);
      alert("Failed to save POI.");
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeletePOI = async (poi) => {
    if (!window.confirm(`Delete POI "${poi.name}"?`)) return;
    try {
      await deletePOI(buildingId, Number(floorNumber), poi);
      const updatedPois = await getPOIsByFloor(buildingId, floorNumber);
      setPois(updatedPois);
    } catch (err) {
      alert("Failed to delete POI.");
    }
  };

  const calculateEstimatedDistance = (pts) => {
    let dist = 0;
    for (let i = 1; i < pts.length; i++) {
      // Simple distance on 100x100 grid (needs actual meter conversion if possible, but grid is ok for now)
      const dx = pts[i].x - pts[i - 1].x;
      const dy = pts[i].y - pts[i - 1].y;
      dist += Math.sqrt(dx * dx + dy * dy);
    }
    return parseFloat(dist.toFixed(1));
  };

  // Circle Marker with Hover Tooltip
  const POIMarker = ({ x, y, color, label, isTarget = false }) => {
    // Compensate for preserveAspectRatio="none" stretching
    // The overlay is 100x100 mapped to container width x height
    const vp = viewportRef.current;
    const vpW = vp?.offsetWidth || 1;
    const vpH = vp?.offsetHeight || 1;
    const aspect = vpW / vpH;
    // To make a perfect circle, use ellipse with adjusted radii
    const baseR = 5; // radius in pixels we want on screen
    const rx = (baseR / vpW) * 100 / scale;
    const ry = (baseR / vpH) * 100 / scale;

    return (
      <g className="poi-marker-group" style={{ pointerEvents: 'all' }}>
        <ellipse
          cx={x} cy={y} rx={rx} ry={ry}
          fill={isTarget ? color : "#2d3748"}
          stroke="#fff"
          strokeWidth={Math.min(rx, ry) * 0.3}
          className="poi-marker-dot"
        />
        {label && (
          <foreignObject
            x={x - 5} y={y - 4}
            width="10" height="3"
            style={{ overflow: 'visible', pointerEvents: 'none' }}
          >
            <div className="poi-tooltip">
              {label}
            </div>
          </foreignObject>
        )}
      </g>
    );
  };

  return (
    <div className="ir-main-layout">
      {/* Left Area: Map Viewer */}
      <div className="ir-map-container">
        <div className="ir-map-viewer">
          {loading ? (
            <div className="loading-spinner">Loading floor map...</div>
          ) : currentFloorMap ? (
            <div
              className="ir-map-viewport"
              ref={viewportRef}
              onClick={handleMapClick}
              style={{
                transform: `scale(${scale})`,
                transformOrigin: '50% 50%',
                cursor: 'crosshair',
                position: 'relative',
              }}
            >
              <div
                style={{
                  position: 'relative',
                  width: '100%',
                  height: '100%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {/* Render Map */}
                {currentFloorMap.svgContent ? (
                  <div
                    className="ir-map-svg-wrapper"
                    ref={svgWrapperRef}
                    dangerouslySetInnerHTML={{ __html: currentFloorMap.svgContent }}
                  />
                ) : (
                  <img
                    src={currentFloorMap.mapUrl}
                    alt="Floor Map"
                    onLoad={handleImageLoad}
                    style={{ maxWidth: '100%', maxHeight: '100%', display: 'block', pointerEvents: 'none', objectFit: 'contain', margin: 'auto' }}
                  />
                )}

                {/* Overlay */}
                <svg
                  viewBox="0 0 100 100"
                  preserveAspectRatio="none"
                  style={{
                    position: 'absolute',
                    top: 0, left: 0,
                    width: '100%', height: '100%',
                    pointerEvents: 'none'
                  }}
                >
                  {activeTab === 'route' && fullRoutePoints.length > 1 && (
                    <polyline
                      points={fullRoutePoints.map(p => `${p.x},${p.y}`).join(' ')}
                      fill="none"
                      stroke="#1c1c1e"
                      strokeWidth={2 / scale}
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      style={{ vectorEffect: 'non-scaling-stroke' }}
                    />
                  )}

                  {pois.map((poi, idx) => (
                    <POIMarker
                      key={`${poi.name}-${idx}`}
                      x={poi.x}
                      y={poi.y}
                      color={poi.name === fromLocationId ? "#10b981" : poi.name === toLocationId ? "#ef4444" : "#3b82f6"}
                      label={poi.name}
                      isTarget={poi.name === fromLocationId || poi.name === toLocationId}
                    />
                  ))}

                  {points.map((p, i) => (
                    activeTab === 'route' ? (
                      <circle key={i} cx={p.x} cy={p.y} r={1.2 / scale} fill="#1c1c1e" stroke="white" strokeWidth={0.3 / scale} />
                    ) : (
                      <POIMarker key={i} x={p.x} y={p.y} color="#1c1c1e" label="New POI" />
                    )
                  ))}
                </svg>
              </div>
            </div>
          ) : (
            <div style={{ textAlign: 'center', color: '#9aa4af' }}>
              <FaLayerGroup size={48} style={{ opacity: 0.2, marginBottom: '1rem' }} />
              <div>Please select a floor with an uploaded map</div>
            </div>
          )}

          <div className="ir-zoom-controls">
            <button onClick={() => handleZoom(0.25)} title="Zoom In"><FaPlus /></button>
            <button onClick={() => handleZoom(-0.25)} title="Zoom Out"><FaMinus /></button>
          </div>
        </div>

        <div className="ir-map-controls">
          <button className="ir-btn-black" onClick={handleClearPoints}>Clear all</button>
          <button className="ir-btn-black" onClick={handleUndoPoint}>Undo</button>
        </div>
      </div>

      {/* Right Area: Sidebar Form */}
      <div className="ir-side-panel">
        <div className="ir-tabs-toggle">
          <button
            className={`ir-tab-btn ${activeTab === 'route' ? 'active' : ''}`}
            onClick={() => { setActiveTab('route'); setPoints([]); }}
          >
            Add Route
          </button>
          <button
            className={`ir-tab-btn ${activeTab === 'poi' ? 'active' : ''}`}
            onClick={() => { setActiveTab('poi'); setPoints([]); }}
          >
            Add POI
          </button>
        </div>

        <div className="ir-form-content">
          {activeTab === 'route' ? (
            <>
              <div className="ir-form-group">
                <label>Start Point</label>
                <select
                  className="ir-input-pill"
                  value={fromLocationId}
                  onChange={(e) => setFromLocationId(e.target.value)}
                >
                  <option value="">Select Start Point</option>
                  {pois.map((p, i) => (
                    <option key={`${p.name}-${i}`} value={p.name}>{p.name}</option>
                  ))}
                </select>
              </div>

              <div className="ir-form-group">
                <label>Destination</label>
                <select
                  className="ir-input-pill"
                  value={toLocationId}
                  onChange={(e) => setToLocationId(e.target.value)}
                >
                  <option value="">Select Destination</option>
                  {pois.map((p, i) => (
                    <option key={`${p.name}-${i}`} value={p.name}>{p.name}</option>
                  ))}
                </select>
              </div>

              <button
                className="ir-btn-save"
                onClick={handleSaveRoute}
                disabled={isSaving || !fromLocationId || !toLocationId}
              >
                {isSaving ? 'Saving...' : 'Save Route'}
              </button>

              <div className="ir-list-section">
                <label>Routes</label>
                <div className="ir-pills-grid">
                  {existingRoutes.map(route => (
                    <div key={route.id} className="ir-pill-item">
                      <span className="ir-pill-text">
                        {route.fromLocation}→{route.toLocation}
                      </span>
                      <button className="ir-pill-close" onClick={() => handleDeleteRoute(route.id)}>×</button>
                    </div>
                  ))}
                </div>
              </div>
            </>
          ) : (
            <>
              <div className="ir-form-group">
                <label>POI Name</label>
                <input
                  type="text"
                  className="ir-input-pill"
                  placeholder="Enter POI Name"
                  value={poiName}
                  onChange={(e) => setPoiName(e.target.value)}
                />
              </div>

              <button
                className="ir-btn-save"
                onClick={handleSavePOI}
                disabled={isSaving || points.length === 0 || !poiName}
              >
                {isSaving ? 'Saving...' : 'Save POI'}
              </button>

              <div className="ir-list-section">
                <label>POIs</label>
                <div className="ir-pills-grid">
                  {pois.map((poi, idx) => (
                    <div key={`${poi.name}-${idx}`} className="ir-pill-item">
                      <span className="ir-pill-text">
                        {poi.name}
                      </span>
                      <button className="ir-pill-close" onClick={() => handleDeletePOI(poi)}>×</button>
                    </div>
                  ))}
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default RouteManagement;
