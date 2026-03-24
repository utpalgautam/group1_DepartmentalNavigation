// src/components/Sidebar.jsx
import { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  LuLayoutDashboard,
  LuBuilding2,
  LuUsers,
  LuRoute,
  LuGraduationCap,
  LuFlaskConical,
  LuLogOut
} from 'react-icons/lu';
import { logoutAdmin } from '../services/authService';

const Sidebar = () => {
  const navigate = useNavigate();
  const [showLogoutModal, setShowLogoutModal] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);

  const handleLogoutConfirm = async () => {
    setLoggingOut(true);
    try {
      await logoutAdmin();
      navigate('/login', { replace: true });
    } catch (err) {
      console.error('Logout failed:', err);
      setLoggingOut(false);
      setShowLogoutModal(false);
    }
  };

  return (
    <>
      <div className="sidebar">
        <div className="logo">
          <div className="badge">D.</div>
        </div>

        <div className="nav-section">
          <div className="nav-title">Navigation</div>
          <ul className="nav-links">
            <li>
              <NavLink to="/" end className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
                <LuLayoutDashboard />
              </NavLink>
            </li>
            <li>
              <NavLink to="/buildings" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
                <LuBuilding2 />
              </NavLink>
            </li>
            <li>
              <NavLink to="/faculties" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
                <LuGraduationCap />
              </NavLink>
            </li>
            <li>
              <NavLink to="/halls-labs" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
                <LuFlaskConical />
              </NavLink>
            </li>
            <li>
              <NavLink to="/routing" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
                <LuRoute />
              </NavLink>
            </li>
            <li>
              <NavLink to="/users" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
                <LuUsers />
              </NavLink>
            </li>
          </ul>
        </div>

        {/* Bottom — Logout Button */}
        <div className="sidebar-bottom">
          <button
            id="logout-btn"
            className="sidebar-logout-btn"
            onClick={() => setShowLogoutModal(true)}
            title="Logout"
          >
            <LuLogOut />
          </button>
        </div>
      </div>

      {/* ── Logout Confirmation Modal ── */}
      {showLogoutModal && (
        <div className="logout-overlay" onClick={() => !loggingOut && setShowLogoutModal(false)}>
          <div className="logout-modal" onClick={(e) => e.stopPropagation()}>
            {/* Icon */}
            <div className="logout-modal-icon">
              <LuLogOut />
            </div>

            <h2 className="logout-modal-title">Sign Out?</h2>
            <p className="logout-modal-body">
              Are you sure you want to log out of the admin portal? Your session will be ended.
            </p>

            <div className="logout-modal-actions">
              <button
                id="logout-cancel-btn"
                className="logout-btn-cancel"
                onClick={() => setShowLogoutModal(false)}
                disabled={loggingOut}
              >
                Cancel
              </button>
              <button
                id="logout-confirm-btn"
                className="logout-btn-confirm"
                onClick={handleLogoutConfirm}
                disabled={loggingOut}
              >
                {loggingOut ? (
                  <>
                    <span className="logout-spinner" />
                    Logging out…
                  </>
                ) : (
                  'Yes, Log Out'
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default Sidebar;