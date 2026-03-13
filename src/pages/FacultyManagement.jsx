import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import FacultyTable from '../components/FacultyTable';
import FacultyForm from '../components/FacultyForm';
import Header from '../components/Header';
import Pagination from '../components/Pagination';
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
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 4;

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
        <Header
          title={viewState === 'add' ? 'Add New faculty' : 'Edit faculty'}
          searchDisabled={true}
          onBack={() => { setViewState('list'); setSelectedFaculty(null); }}
        />
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
      <Header
        title="Faculty"
        searchTerm={searchQuery}
        onSearchChange={e => {
          setSearchQuery(e.target.value);
          setCurrentPage(1);
        }}
      />

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
        <>
          <FacultyTable
            facultyData={processedData.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage)}
            buildings={buildings}
            onEdit={handleEdit}
            onDelete={handleDelete}
          />
          <Pagination 
            currentPage={currentPage}
            totalItems={processedData.length}
            itemsPerPage={itemsPerPage}
            onPageChange={setCurrentPage}
          />
        </>
      )}
    </div>
  );
};

export default FacultyManagement;