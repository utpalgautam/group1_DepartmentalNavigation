// src/components/Header.jsx
import { FaSearch } from 'react-icons/fa';

const Header = ({ title, searchTerm, onSearchChange, searchDisabled = false, onBack }) => {
  return (
    <div className="db-header">
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
        {onBack && (
          <button className="fac-back-btn" onClick={onBack}>
            ←
          </button>
        )}
        <h1 className="db-title">{title}</h1>
      </div>
      <div className="db-header-right">
        <div className="db-search-bar">
          <FaSearch className="db-search-icon" />
          <input
            type="text"
            placeholder="Search..."
            value={searchTerm}
            onChange={onSearchChange}
            disabled={searchDisabled}
          />
        </div>
        <div className="db-avatar-img">
          <img
            src="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=100&auto=format&fit=crop"
            alt="Profile"
          />
        </div>
      </div>
    </div>
  );
};

export default Header;