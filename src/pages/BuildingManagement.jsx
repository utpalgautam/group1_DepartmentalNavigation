// src/pages/BuildingManagement.jsx
import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import Header from '../components/Header';
import BuildingCards from '../components/BuildingCards';
import BuildingDetails from '../components/BuildingDetails';
import BuildingForm from '../components/BuildingForm';
import { fetchAllBuildings, addBuilding, updateBuilding, deleteBuilding } from '../services/buildingService';

const BuildingManagement = () => {
  const location = useLocation();
  const [viewState, setViewState] = useState(location.state?.openForm ? 'add' : 'list'); // list, details, add, edit
  const [selectedBuilding, setSelectedBuilding] = useState(null);
  const [buildings, setBuildings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortAsc, setSortAsc] = useState(true);

  useEffect(() => {
    fetchBuildings();
  }, []);

  const fetchBuildings = async () => {
    try {
      setLoading(true);
      setError('');
      const data = await fetchAllBuildings();
      setBuildings(data);
    } catch (err) {
      console.error('Error fetching buildings:', err);
      setError('Unable to fetch buildings. Check your Firestore connection.');
    } finally {
      setLoading(false);
    }
  };

  const handleBuildingClick = (building) => {
    setSelectedBuilding(building);
    setViewState('details');
  };

  const handleAddBuilding = () => {
    setSelectedBuilding(null);
    setViewState('add');
  };

  const handleEditBuilding = (building) => {
    setSelectedBuilding(building);
    setViewState('edit');
  };

  const generateNextId = () => {
    if (buildings.length === 0) return 'B1';
    const ids = buildings
      .map(b => b.id)
      .filter(id => /^B\d+$/.test(id))
      .map(id => parseInt(id.substring(1)))
      .filter(num => !isNaN(num));
    const maxId = ids.length > 0 ? Math.max(...ids) : 0;
    return `B${maxId + 1}`;
  };

  const handleSaveBuilding = async (buildingData) => {
    try {
      setError('');
      if (viewState === 'add') {
        const customId = generateNextId();
        await addBuilding(buildingData, customId);
      } else if (viewState === 'edit') {
        await updateBuilding(selectedBuilding.id, buildingData);
      }
      await fetchBuildings();
      setViewState('list');
      setSelectedBuilding(null);
    } catch (err) {
      console.error('Error saving building:', err);
      setError(err.message || 'Failed to save building. Please try again.');
    }
  };

  const handleDeleteBuilding = async (buildingId) => {
    if (!window.confirm('Are you sure you want to delete this building? This action cannot be undone.')) return;
    try {
      setLoading(true);
      setError('');
      await deleteBuilding(buildingId);
      await fetchBuildings();
    } catch (err) {
      console.error('Error deleting building:', err);
      setError('Failed to delete building.');
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = () => {
    setViewState('list');
    setSelectedBuilding(null);
    setError('');
  };

  const handleBackToDirectory = () => {
    setViewState('list');
    setSelectedBuilding(null);
  };

  // Derive filtered + sorted buildings
  const processedBuildings = buildings
    .filter(b => b.name?.toLowerCase().includes(searchQuery.toLowerCase()))
    .sort((a, b) => sortAsc
      ? (a.name || '').localeCompare(b.name || '')
      : (b.name || '').localeCompare(a.name || '')
    );

  if (viewState === 'details' && selectedBuilding) {
    return (
      <BuildingDetails
        building={selectedBuilding}
        onBack={handleBackToDirectory}
        onEdit={() => handleEditBuilding(selectedBuilding)}
      />
    );
  }

  if (viewState === 'add' || viewState === 'edit') {
    return (
      <BuildingForm
        building={selectedBuilding}
        onSave={handleSaveBuilding}
        onCancel={handleCancel}
      />
    );
  }

  return (
    <div>
      {/* Page Header */}
      <div className="buildings-page-header">
        <h1 className="buildings-page-title">Buildings</h1>

        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          {/* Search */}
          <div className="buildings-search-wrapper">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="buildings-search-icon" style={{ position: 'absolute', left: '1.2rem', top: '50%', transform: 'translateY(-50%)' }}>
              <circle cx="11" cy="11" r="8"></circle>
              <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
            <input
              className="buildings-search-input"
              style={{ paddingLeft: '2.8rem' }}
              placeholder="Search..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
            />
          </div>

          {/* User Avatar */}
          <div className="buildings-avatar">
            <div className="buildings-avatar-circle">AR</div>
          </div>
        </div>
      </div>

      {error && (
        <div style={{
          padding: '1rem',
          marginBottom: '1.5rem',
          background: '#fee',
          border: '1px solid #fcc',
          borderRadius: '0.375rem',
          color: '#c33'
        }}>
          ⚠️ {error}
        </div>
      )}

      {/* Toolbar */}
      <div className="buildings-toolbar">
        <button className="buildings-sort-btn" onClick={() => setSortAsc(s => !s)}>
          Sort {sortAsc ? '↑↓' : '↓↑'}
        </button>
        <button className="buildings-add-btn" onClick={handleAddBuilding} disabled={loading}>
          + Add Building
        </button>
      </div>

      {/* Building Cards Grid */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: '3rem' }}>
          <p style={{ color: '#94a3b8' }}>Loading buildings...</p>
        </div>
      ) : (
        <BuildingCards
          buildings={processedBuildings}
          onBuildingClick={handleBuildingClick}
          onEdit={handleEditBuilding}
          onDelete={handleDeleteBuilding}
          onAddBuilding={handleAddBuilding}
        />
      )}
    </div>
  );
};

export default BuildingManagement;