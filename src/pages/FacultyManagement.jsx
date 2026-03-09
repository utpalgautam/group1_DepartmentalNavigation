import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import FacultyTable from '../components/FacultyTable';
import FacultyForm from '../components/FacultyForm';
import { fetchAllFaculty, addFaculty, updateFaculty, deleteFaculty } from '../services/facultyService';
import { fetchAllBuildings } from '../services/buildingService';

const FacultyManagement = () => {
  const location = useLocation();
  const [viewState, setViewState] = useState(location.state?.openForm ? 'add' : 'list'); // list, add, edit
  const [selectedFaculty, setSelectedFaculty] = useState(null);
  const [facultyData, setFacultyData] = useState([]);
  const [buildings, setBuildings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortAsc, setSortAsc] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [fData, bData] = await Promise.all([
        fetchAllFaculty(),
        fetchAllBuildings()
      ]);
      setFacultyData(fData);
      setBuildings(bData);
    } catch (err) {
      console.error(err);
      setError('Failed to load data.');
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (faculty) => {
    setSelectedFaculty(faculty);
    setViewState('edit');
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this faculty member?')) {
      try {
        await deleteFaculty(id);
        await loadData();
      } catch (err) {
        console.error("Failed to delete faculty:", err);
        setError("Failed to delete faculty member. Please try again.");
      }
    }
  };

  const handleSave = async (faculty) => {
    try {
      if (viewState === 'add') {
        await addFaculty(faculty);
      } else {
        await updateFaculty(faculty.id, faculty);
      }
      await loadData();
      setViewState('list');
      setSelectedFaculty(null);
    } catch (err) {
      console.error("Failed to save faculty:", err);
      throw err; // throw so the form can catch and display
    }
  };

  const processedData = facultyData
    .filter(f => f.name?.toLowerCase().includes(searchQuery.toLowerCase()) || f.cabin?.toLowerCase().includes(searchQuery.toLowerCase()))
    .sort((a, b) => sortAsc
      ? (a.name || '').localeCompare(b.name || '')
      : (b.name || '').localeCompare(a.name || '')
    );

  if (viewState === 'add' || viewState === 'edit') {
    return (
      <div className="fac-page">
        <div className="fac-header-row" style={{ marginBottom: '1.5rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <button className="bf-back-btn" onClick={() => { setViewState('list'); setSelectedFaculty(null); }}>
              ←
            </button>
            <h1 className="fac-title">{viewState === 'add' ? 'Add New faculty' : 'Edit faculty'}</h1>
          </div>
          <div className="fac-header-actions">
            <div className="buildings-search-wrapper">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="buildings-search-icon" style={{ position: 'absolute', left: '1.2rem', top: '50%', transform: 'translateY(-50%)' }}>
                <circle cx="11" cy="11" r="8"></circle>
                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
              </svg>
              <input
                className="buildings-search-input"
                style={{ paddingLeft: '2.8rem' }}
                placeholder="Search..."
              />
            </div>
            <div className="buildings-avatar">
              <div className="buildings-avatar-circle" style={{ background: '#e0ecfc', color: '#e0ecfc' }}></div>
            </div>
          </div>
        </div>
        <FacultyForm
          faculty={selectedFaculty}
          buildings={buildings}
          onSave={handleSave}
          onCancel={() => { setViewState('list'); setSelectedFaculty(null); }}
        />
      </div>
    );
  }

  return (
    <div className="fac-page">
      {/* Header Row */}
      <div className="fac-header-row">
        <h1 className="fac-title">Faculty</h1>
        <div className="fac-header-actions">
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
          <div className="buildings-avatar">
            <div className="buildings-avatar-circle" style={{ background: '#e0ecfc', color: '#e0ecfc' }}></div>
          </div>
        </div>
      </div>

      {error && (
        <div style={{ padding: '1rem', marginBottom: '1rem', background: '#fee', border: '1px solid #fcc', borderRadius: '0.375rem', color: '#c33' }}>
          {error}
        </div>
      )}

      {/* Toolbar Layer */}
      <div className="fac-toolbar">
        <button className="fac-btn-purple" onClick={() => setSortAsc(s => !s)}>
          Sort <span>{sortAsc ? '↑↓' : '↓↑'}</span>
        </button>
        <button className="fac-btn-purple" onClick={() => { setSelectedFaculty(null); setViewState('add'); }} disabled={loading}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          Add Faculty
        </button>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '3rem', color: '#9aa4af' }}>Loading ...</div>
      ) : (
        <FacultyTable
          facultyData={processedData}
          buildings={buildings}
          onEdit={handleEdit}
          onDelete={handleDelete}
        />
      )}
    </div>
  );
};

export default FacultyManagement;