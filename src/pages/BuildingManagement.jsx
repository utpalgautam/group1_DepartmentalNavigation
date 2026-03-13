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
  const processedBuildings = (buildings || [])
    .filter(b => (b?.name || '').toLowerCase().includes(searchQuery.toLowerCase()))
    .sort((a, b) => {
      const nameA = a?.name || '';
      const nameB = b?.name || '';
      return sortAsc
        ? nameA.localeCompare(nameB)
        : nameB.localeCompare(nameA);
    });

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
    const pageTitle = viewState === 'add' ? 'Add Buildings' : 'Edit Buildings';
    return (
      <div className="bf-page">
        <Header
          title={pageTitle}
          searchDisabled={true}
          onBack={handleCancel}
        />
        <BuildingForm
          building={selectedBuilding}
          onSave={handleSaveBuilding}
          onCancel={handleCancel}
        />
      </div>
    );
  }

  return (
    <div>
      <Header
        title="Buildings"
        searchTerm={searchQuery}
        onSearchChange={e => setSearchQuery(e.target.value)}
      />

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