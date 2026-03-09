// src/pages/Dashboard.jsx
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FaSearch, FaChalkboardTeacher, FaBuilding, FaDoorOpen, FaUserPlus } from 'react-icons/fa';
import { HiOutlineAcademicCap } from 'react-icons/hi';
import { BarChart, Bar, AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { fetchAllFaculty } from '../services/facultyService';
import { fetchAllHalls } from '../services/hallsService';
import { fetchAllLabs } from '../services/labsService';
import { fetchAllBuildings } from '../services/buildingService';
import { getSearchesPerBuilding, getSearchesPerDay } from '../services/analyticsService';

const Dashboard = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState({ faculty: 0, halls: 0, labs: 0 });
  const [buildingChartData, setBuildingChartData] = useState([]);
  const [dailyChartData, setDailyChartData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true);
        const [faculty, halls, labs, bldgChart, dayChart] = await Promise.all([
          fetchAllFaculty(),
          fetchAllHalls(),
          fetchAllLabs(),
          getSearchesPerBuilding(),
          getSearchesPerDay(7)
        ]);
        setStats({
          faculty: faculty.length,
          halls: halls.length,
          labs: labs.length
        });
        setBuildingChartData(bldgChart);
        setDailyChartData(dayChart);
      } catch (err) {
        console.error('Dashboard load error:', err);
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, []);

  const quickActions = [
    {
      label: 'Add Faculty', sub: 'Nearby', path: '/faculties',
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#000" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <rect x="3" y="4" width="18" height="16" rx="2" />
          <circle cx="12" cy="11" r="3" />
          <path d="M7 20v-2a4 4 0 0 1 10 0v2" />
        </svg>
      )
    },
    {
      label: 'Add Building', sub: 'Nearby', path: '/buildings',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#000" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <rect x="4" y="2" width="12" height="20" rx="1" />
          <path d="M8 6h.01" />
          <path d="M12 6h.01" />
          <path d="M8 10h.01" />
          <path d="M12 10h.01" />
          <path d="M8 14h.01" />
          <path d="M12 14h.01" />
          <path d="M8 18h.01" />
          <path d="M12 18h.01" />
          <rect x="16" y="10" width="4" height="12" />
        </svg>
      )
    },
    {
      label: 'Add Halls/Labs', sub: 'Nearby', path: '/halls-labs',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#000" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M10 3v7.3l-4.7 9.5A2 2 0 0 0 7 23h10a2 2 0 0 0 1.7-3.2L14 10.3V3" />
          <path d="M8.5 3h7" />
          <path d="M7 16h10" />
        </svg>
      )
    },
    {
      label: 'Add User', sub: 'Nearby', path: '/users',
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#000" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
          <circle cx="9" cy="7" r="4" />
          <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
          <path d="M16 3.13a4 4 0 0 1 0 7.75" />
        </svg>
      )
    },
  ];

  return (
    <div className="db-page">
      {/* Header */}
      <div className="db-header">
        <h1 className="db-title">Dashboard</h1>
        <div className="db-header-right">
          <div className="db-search-bar">
            <FaSearch className="db-search-icon" />
            <input type="text" placeholder="Search..." disabled />
          </div>
          <div className="db-avatar">AR</div>
        </div>
      </div>

      {/* Stats Row */}
      <div className="db-stats-row">
        {/* Welcome Card */}
        <div className="db-welcome-card">
          <div className="db-welcome-emoji">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ color: '#0369a1' }}>
              <path d="M18 8a6 6 0 0 0-9.33-5H8a6 6 0 0 0-6 6v10a6 6 0 0 0 6 6h10a6 6 0 0 0 6-6V8Z" />
              <path d="m8 12 4-4" />
              <path d="m11 15 4-4" />
              <path d="m14 18 4-4" />
            </svg>
          </div>
          <h2>Welcome, Utpal</h2>
          <p>System is active and stable.</p>
        </div>

        {/* Faculty Count */}
        <div className="db-stat-card db-stat-purple">
          <div className="db-stat-icon">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="#000">
              <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z" />
            </svg>
          </div>
          <div className="db-stat-number">{loading ? '—' : stats.faculty}</div>
          <div className="db-stat-label">Total Faculty</div>
        </div>

        {/* Halls Count */}
        <div className="db-stat-card db-stat-green">
          <div className="db-stat-icon">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="#000">
              <path d="M12 2L1 7v2h22V7L12 2zm-8 7h2v7H4V9zm6 0h2v7h-2V9zm6 0h2v7h-2V9zm-12 9v2h16v-2H4z" />
            </svg>
          </div>
          <div className="db-stat-number">{loading ? '—' : stats.halls}</div>
          <div className="db-stat-label">Total Halls</div>
        </div>

        {/* Labs Count */}
        <div className="db-stat-card db-stat-beige">
          <div className="db-stat-icon">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="#000">
              <path d="M19.3 16.9L15 9V4h1V2H8v2h1v5L4.7 16.9C4.2 17.8 4.1 18.7 4.5 19.6 4.9 20.5 5.7 21 6.7 21h10.6c.9 0 1.8-.5 2.2-1.4.4-.9.3-1.8-.2-2.7zM11 4h2v5.3l1.8 3.7H9.2L11 9.3V4z" />
            </svg>
          </div>
          <div className="db-stat-number">{loading ? '—' : stats.labs}</div>
          <div className="db-stat-label">Total Labs</div>
        </div>
      </div>

      {/* Quick Actions + Charts */}
      <h3 className="db-section-title">Quick Actions</h3>
      <div className="db-content-grid">
        <div className="db-actions-grid">
          {quickActions.map((action, idx) => (
            <div
              key={idx}
              className="db-action-card"
              onClick={() => navigate(action.path, { state: { openForm: true } })}
            >
              <div className="db-action-icon">{action.icon}</div>
              <div className="db-action-text">
                <span className="db-action-sub">{action.sub}</span>
                <span className="db-action-label">{action.label}</span>
              </div>
            </div>
          ))}

          {/* Right Column: Small Chart (Searches per Building) */}
          <div className="db-chart-dark db-chart-small">
            <div className="db-chart-title">Searches by Building</div>
            <ResponsiveContainer width="100%" height={120}>
              <BarChart data={buildingChartData} margin={{ top: 10, right: 10, left: -15, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 9, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 9, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
                <Tooltip
                  contentStyle={{ background: '#2d3748', border: 'none', borderRadius: 8, color: '#fff', fontSize: 12 }}
                  cursor={{ fill: 'rgba(255,255,255,0.05)' }}
                />
                <Bar dataKey="searches" radius={[4, 4, 0, 0]} fill="#60a5fa" barSize={24} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Big Chart Row: Searches per Day */}
      <div className="db-chart-row">
        <div className="db-chart-dark db-chart-large">
          <div className="db-chart-title">Searches per Day</div>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={dailyChartData} margin={{ top: 10, right: 20, left: -15, bottom: 0 }}>
              <defs>
                <linearGradient id="searchGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#60a5fa" stopOpacity={0.4} />
                  <stop offset="95%" stopColor="#60a5fa" stopOpacity={0.0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.08)" vertical={false} />
              <XAxis dataKey="day" tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ background: '#2d3748', border: 'none', borderRadius: 8, color: '#fff', fontSize: 12 }}
                cursor={{ stroke: 'rgba(255,255,255,0.2)' }}
              />
              <Area type="monotone" dataKey="searches" stroke="#60a5fa" strokeWidth={2} fill="url(#searchGrad)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Bottom Strip */}
      <div className="db-bottom-strip"></div>
    </div>
  );
};

export default Dashboard;