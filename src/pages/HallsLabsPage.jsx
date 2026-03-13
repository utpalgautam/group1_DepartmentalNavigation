import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import Header from '../components/Header';
import { FaArrowLeft } from 'react-icons/fa';
import HallsLabsDirectory from '../components/HallsLabsDirectory';
import HallsLabsForm from '../components/HallsLabsForm';
import Pagination from '../components/Pagination';
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
  const [sortAsc, setSortAsc] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 4;

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

  const getProcessedData = () => {
    let filtered = hallsData.filter(item =>
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.building.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.type || '').toLowerCase().includes(searchTerm.toLowerCase())
    );

    filtered.sort((a, b) => {
      return sortAsc
        ? a.name.localeCompare(b.name)
        : b.name.localeCompare(a.name);
    });

    return filtered;
  };

  const processedData = getProcessedData();
  const paginatedData = processedData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  if (viewState === 'add' || viewState === 'edit') {
    const pageTitle = viewState === 'add'
      ? "Add New Halls/Labs"
      : `Edit ${selectedItem?.category === 'LAB' ? 'Lab' : 'Hall'}`;

    return (
      <div>
        <Header
          title={pageTitle}
          searchDisabled={true}
          onBack={handleCancel}
        />

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
      <Header
        title="Halls/Labs"
        searchTerm={searchTerm}
        onSearchChange={e => {
          setSearchTerm(e.target.value);
          setCurrentPage(1);
        }}
      />

      {error && (
        <div style={{ padding: '1rem', marginBottom: '1rem', background: '#fee', border: '1px solid #fcc', borderRadius: '0.375rem', color: '#c33' }}>
          {error}
        </div>
      )}

      {loading ? (
        <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--muted-gray)' }}>Loading directory...</div>
      ) : (
        <>
          <HallsLabsDirectory
            processedData={paginatedData}
            onAdd={handleAdd}
            onEdit={handleEdit}
            onDelete={handleDelete}
            sortAsc={sortAsc}
            onSortToggle={() => setSortAsc(!sortAsc)}
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

export default HallsLabsPage;