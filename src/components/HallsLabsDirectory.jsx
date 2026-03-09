import { useState } from 'react';
import { FaTrash } from 'react-icons/fa';

const HallsLabsDirectory = ({ hallsData, searchTerm, onAdd, onEdit, onDelete }) => {
  const [sortAsc, setSortAsc] = useState(true);

  let processedData = hallsData.filter(item =>
    item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.building.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.type.toLowerCase().includes(searchTerm.toLowerCase())
  );

  processedData.sort((a, b) => {
    return sortAsc
      ? a.name.localeCompare(b.name)
      : b.name.localeCompare(a.name);
  });

  const getAvatarIcon = (category) => {
    if (category === 'LAB') {
      return (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M10 2v7.31"></path>
          <path d="M14 9.3V1.99"></path>
          <path d="M8.5 2h7"></path>
          <path d="M14 9.3a6.5 6.5 0 1 1-4 0"></path>
          <path d="M5.52 16h12.96"></path>
        </svg>
      );
    }
    return (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <rect x="4" y="2" width="16" height="20" rx="2" ry="2"></rect>
        <path d="M9 22v-4h6v4"></path>
        <path d="M8 6h.01"></path>
        <path d="M16 6h.01"></path>
        <path d="M12 6h.01"></path>
        <path d="M12 10h.01"></path>
        <path d="M12 14h.01"></path>
        <path d="M16 10h.01"></path>
        <path d="M16 14h.01"></path>
        <path d="M8 10h.01"></path>
        <path d="M8 14h.01"></path>
      </svg>
    );
  };

  const getLocationString = (bldg, floor) => {
    const parts = [];
    if (bldg) parts.push(`${bldg} Building`);
    if (floor) parts.push(`Floor ${floor}`);
    return parts.join(', ') || 'Location Pending';
  };

  return (
    <div>
      <div className="hl-toolbar">
        <button className="hl-btn-sort" onClick={() => setSortAsc(!sortAsc)}>
          Sort {sortAsc ? '↓' : '↑'}
        </button>
        <button className="hl-btn-green" onClick={onAdd}>
          + Add Hall/Lab
        </button>
      </div>

      <div className="hl-table-container">
        <div className="hl-table-header">
          <span>Room Name</span>
          <span>Location</span>
          <span>Type</span>
          <span style={{ textAlign: 'center' }}>Action</span>
        </div>

        {processedData.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '3rem', color: '#6b7280' }}>
            No halls or labs found matching your search.
          </div>
        ) : (
          processedData.map((item) => (
            <div key={item.id} className="hl-table-row">
              <div className="hl-table-cell hl-cell-room">
                <div className="hl-avatar">
                  {item.mapUrl ? (
                    <img src={item.mapUrl} alt="" className="hl-avatar-img" />
                  ) : (
                    getAvatarIcon(item.category)
                  )}
                </div>
                <div>
                  <div className="hl-cell-strong">{item.name}</div>
                  <div style={{ fontSize: '0.9rem', color: '#9aa4af', marginTop: '0.2rem' }}>
                    {item.category === 'LAB' ? item.department || 'Lab' : item.contactPerson || 'Hall'}
                  </div>
                </div>
              </div>

              <div className="hl-table-cell">
                {getLocationString(item.building, item.floor)}
              </div>

              <div className="hl-table-cell">
                <span style={{
                  padding: '0.4rem 0.8rem',
                  borderRadius: '999px',
                  background: '#D6EDD9',
                  color: '#111',
                  fontSize: '0.8rem',
                  fontWeight: '500'
                }}>
                  {item.category === 'LAB' ? 'Laboratory' : (item.type || 'Hall')}
                </span>
              </div>

              <div className="hl-table-cell" style={{ display: 'flex', gap: '0.8rem', justifyContent: 'center' }}>
                <button className="hl-action-pill" onClick={(e) => { e.stopPropagation(); onEdit(item); }}>
                  Modify
                </button>
                <button className="hl-action-icon" onClick={(e) => { e.stopPropagation(); onDelete(item); }}>
                  <FaTrash size={16} />
                </button>
              </div>
            </div>
          ))
        )}

        <div style={{ padding: '1.5rem', textAlign: 'left', color: '#6b7280', fontSize: '0.95rem' }}>
          Showing 1 to {Math.min(processedData.length, 20)} of {processedData.length}
        </div>
      </div>
    </div>
  );
};

export default HallsLabsDirectory;
