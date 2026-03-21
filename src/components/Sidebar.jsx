// src/components/Sidebar.jsx
import { NavLink } from 'react-router-dom';
import {
  FaTachometerAlt,
  FaBuilding,
  FaUsers,
  FaRoute,
  FaChartBar,
  FaCog,
  FaUniversity,
  FaDoorOpen,
  FaLayerGroup
} from 'react-icons/fa';

const Sidebar = () => {
  return (
    <div className="sidebar">
      <div className="logo">
        <div className="badge">D.</div>
      </div>

      <div className="nav-section">
        <div className="nav-title">Navigation</div>
        <ul className="nav-links">
          <li>
            <NavLink to="/" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaTachometerAlt /> Dashboard
            </NavLink>
          </li>
          <li>
            <NavLink to="/buildings" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaBuilding /> Buildings
            </NavLink>
          </li>
          <li>
            <NavLink to="/faculties" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaUniversity /> Faculties
            </NavLink>
          </li>
          <li>
            <NavLink to="/halls-labs" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaDoorOpen /> Halls & Labs
            </NavLink>
          </li>
          <li>
            <NavLink to="/routing" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaRoute /> Routing
            </NavLink>
          </li>
        </ul>
      </div>

      {/* Removed Management section */}

      <div className="nav-section">
        <ul className="nav-links">
          <li>
            <NavLink to="/users" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              <FaUsers />
            </NavLink>
          </li>
        </ul>
      </div>

      <div className="sidebar-bottom">
        <FaCog className="sidebar-bottom-icon" />
        <svg className="sidebar-bottom-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
          <polyline points="16 17 21 12 16 7" />
          <line x1="21" y1="12" x2="9" y2="12" />
        </svg>
      </div>
    </div>
  );
};

export default Sidebar;