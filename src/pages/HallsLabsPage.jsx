import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import Header from '../components/Header';
import { FaSearch, FaArrowLeft } from 'react-icons/fa';
import HallsLabsDirectory from '../components/HallsLabsDirectory';
import HallsLabsForm from '../components/HallsLabsForm';
import { fetchAllHalls, addHall, updateHall, deleteHall } from '../services/hallsService';
import { fetchAllLabs, addLab, updateLab, deleteLab } from '../services/labsService';
import { fetchAllBuildings } from '../services/buildingService';

const HallsLabsPage = () => {
  const location = useLocation();
  const [viewState, setViewState] = useState(location.state?.openForm ? 'add' : 'list'); // list, add, edit
  const [selectedItem, setSelectedItem] = useState(null);
  const [hallsData, setHallsData] = useState([]);
  const [buildings, setBuildings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [hData, lData, bData] = await Promise.all([
        fetchAllHalls(),
        fetchAllLabs(),
        fetchAllBuildings()
      ]);
      setHallsData([...hData, ...lData]);
      setBuildings(bData);
    } catch (err) {
      console.error(err);
      setError('Failed to load data. Please refresh.');
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = () => {
    setSelectedItem(null);
    setViewState('add');
  };

  const handleEdit = (item) => {
    setSelectedItem(item);
    setViewState('edit');
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Are you sure you want to delete this ${item.category === 'LAB' ? 'lab' : 'hall'}?`)) {
      try {
        if (item.category === 'LAB') {
          await deleteLab(item.id);
        } else {
          await deleteHall(item.id);
        }
        await loadData();
      } catch (err) {
        console.error("Delete failed:", err);
        setError("Failed to delete. Please try again.");
      }
    }
  };

  const handleSave = async (item) => {
    try {
      if (viewState === 'add') {
        if (item.category === 'LAB') {
          await addLab(item);
        } else {
          await addHall(item);
        }
      } else {
        if (item.category === 'LAB') {
          await updateLab(item.id, item);
        } else {
          await updateHall(item.id, item);
        }
      }
      await loadData();
      setViewState('list');
      setSelectedItem(null);
    } catch (err) {
      console.error("Save failed:", err);
      throw err;
    }
  };


  const handleCancel = () => {
    setViewState('list');
    setSelectedItem(null);
  };

  if (viewState === 'add' || viewState === 'edit') {
    const pageTitle = viewState === 'add'
      ? "Add New Halls/Labs"
      : `Edit ${selectedItem?.category === 'LAB' ? 'Lab' : 'Hall'}`;

    return (
      <div>
        <div className="hl-header-row">
          <div style={{ display: 'flex', alignItems: 'center', gap: '1.2rem' }}>
            <button type="button" className="hl-back-btn" onClick={handleCancel}>
              <FaArrowLeft size={16} />
            </button>
            <h1>{pageTitle}</h1>
          </div>
          <div className="hl-header-controls">
            <div className="hl-search-bar">
              <FaSearch />
              <input type="text" placeholder="Search..." disabled />
            </div>
            <div className="hl-user-avatar"></div>
          </div>
        </div>

        <HallsLabsForm
          item={selectedItem}
          buildings={buildings}
          onSave={handleSave}
          onCancel={handleCancel}
        />
      </div>
    );
  }

  return (
    <div>
      {/* Custom Header with Search & Avatar */}
      <div className="hl-header-row">
        <h1>Halls/Labs</h1>
        <div className="hl-header-controls">
          <div className="hl-search-bar">
            <FaSearch />
            <input
              type="text"
              placeholder="Search..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="hl-user-avatar"></div>
        </div>
      </div>

      {error && (
        <div style={{ padding: '1rem', marginBottom: '1rem', background: '#fee', border: '1px solid #fcc', borderRadius: '0.375rem', color: '#c33' }}>
          {error}
        </div>
      )}

      {loading ? (
        <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--muted-gray)' }}>Loading directory...</div>
      ) : (
        <HallsLabsDirectory
          hallsData={hallsData}
          searchTerm={searchTerm}
          onAdd={handleAdd}
          onEdit={handleEdit}
          onDelete={handleDelete}
        />
      )}
    </div>
  );
};

export default HallsLabsPage;