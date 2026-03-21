// src/App.jsx
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import Dashboard from './pages/Dashboard';
import FacultyManagement from './pages/FacultyManagement';
import BuildingManagement from './pages/BuildingManagement';
import UserManagementPage from './pages/UserManagementPage';
import OutdoorMarkersPage from './pages/OutdoorMarkersPage';
import HallsLabsPage from './pages/HallsLabsPage';
import SettingsPage from './pages/SettingsPage';
import InteractiveRoutePage from './pages/InteractiveRoutePage';
import './styles/main.css';

function App() {
  return (
    <Router>
      <div className="app-container">
        <Sidebar />
        <div className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/faculties" element={<FacultyManagement />} />
            <Route path="/buildings" element={<BuildingManagement />} />
            <Route path="/halls-labs" element={<HallsLabsPage />} />
            <Route path="/routing" element={<InteractiveRoutePage />} />
            {/* Removed analytics route */}
            <Route path="/users" element={<UserManagementPage />} />
            <Route path="/settings" element={<SettingsPage />} />
            <Route path="/outdoor-markers" element={<OutdoorMarkersPage />} />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;