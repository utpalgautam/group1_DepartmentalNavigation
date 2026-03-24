import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { LuSearch, LuBuilding2, LuUsers, LuFlaskConical, LuGraduationCap, LuUserPlus, LuSparkles } from 'react-icons/lu';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { db } from '../services/firebaseConfig';
import { collection, getDocs } from 'firebase/firestore';
import { getSearchesPerBuilding, getSearchesPerDay } from '../services/analyticsService';
import Header from '../components/Header';
import { useAuth } from '../context/AuthContext';

const Dashboard = () => {
  const navigate = useNavigate();
  const { userData } = useAuth();
  const [loading, setLoading] = useState(true);
  const [summaryData, setSummaryData] = useState([]);
  const [searchesByBuilding, setSearchesByBuilding] = useState([]);
  const [searchesPerDay, setSearchesPerDay] = useState([]);
  const [timeframe, setTimeframe] = useState('week');

  useEffect(() => {
    const fetchCounts = async () => {
      try {
        setLoading(true);
        const [buildingsSnap, facultySnap, hallsSnap, labsSnap] = await Promise.all([
          getDocs(collection(db, 'buildings')),
          getDocs(collection(db, 'faculty')),
          getDocs(collection(db, 'halls')),
          getDocs(collection(db, 'labs'))
        ]);

        setSummaryData([
          { label: 'Total Buildings', count: buildingsSnap.size, icon: <LuBuilding2 /> },
          { label: 'Total Faculty', count: facultySnap.size, icon: <LuUsers /> },
          { label: 'Total Halls/Labs', count: hallsSnap.size + labsSnap.size, icon: <LuFlaskConical /> },
        ]);

        const allBuildings = buildingsSnap.docs.map(doc => doc.data().name);
        const searchResults = await getSearchesPerBuilding(timeframe);
        
        // Merge: ensure all buildings from database are shown
        const mergedBuildingData = allBuildings.map(name => {
          const match = searchResults.find(r => r.name === name);
          return { name, searches: match ? match.searches : 0 };
        }).sort((a, b) => b.searches - a.searches);

        setSearchesByBuilding(mergedBuildingData);

        const searchesDayData = await getSearchesPerDay(7);
        setSearchesPerDay(searchesDayData);

      } catch (error) {
        console.error("Error fetching dashboard data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchCounts();
  }, [timeframe]);

  const quickActions = [
    {
      label: 'Add Faculty', sub: 'Nearby', path: '/faculties',
      icon: <LuGraduationCap size={24} />
    },
    {
      label: 'Add Building', sub: 'Nearby', path: '/buildings',
      icon: <LuBuilding2 size={24} />
    },
    {
      label: 'Add Halls/Labs', sub: 'Nearby', path: '/halls-labs',
      icon: <LuFlaskConical size={24} />
    },
    {
      label: 'Add User', sub: 'Nearby', path: '/users',
      icon: <LuUserPlus size={24} />
    },
  ];

  return (
    <div className="db-page">
      <Header title="Dashboard" searchDisabled={true} />

      {/* Stats Row */}
      <div className="db-stats-row">
        {/* Welcome Card */}
        <div className="db-welcome-card">
          <div className="db-card-circle-bg"></div>
          <div className="db-welcome-content">
            <div className="db-welcome-emoji">
              <LuSparkles size={32} color="black" />
            </div>
            <h2>Welcome, {userData?.name || 'Admin'}</h2>
            <p>System is active and stable.</p>
          </div>
        </div>

        {/* Render Summary Data Cards */}
        <div className="db-stat-card db-stat-purple">
          <div className="db-stat-icon"><LuUsers color="#000" /></div>
          <div className="db-stat-number">{loading ? '—' : (summaryData[1]?.count || '124')}</div>
          <div className="db-stat-label">Total Faculty</div>
        </div>
        <div className="db-stat-card db-stat-green">
          <div className="db-stat-icon"><LuBuilding2 color="#000" /></div>
          <div className="db-stat-number">{loading ? '—' : (summaryData[0]?.count || '45')}</div>
          <div className="db-stat-label">Total Buildings</div>
        </div>
        <div className="db-stat-card db-stat-beige">
          <div className="db-stat-icon"><LuFlaskConical color="#000" /></div>
          <div className="db-stat-number">{loading ? '—' : (summaryData[2]?.count || '18')}</div>
          <div className="db-stat-label">Total Labs/Hall</div>
        </div>
      </div>

      {/* Quick Actions Grid Structure from Image 2 */}
      <h3 className="db-section-title">Quick Actions</h3>
      <div className="db-actions-grid">
        {/* Row 1, Column 1 */}
        <div className="db-action-card" onClick={() => navigate('/faculties', { state: { openForm: true } })}>
          <div className="db-action-icon-wrapper"><div className="db-action-icon-circle">{quickActions[0].icon}</div></div>
          <div className="db-action-text"><span className="db-action-sub">Nearby</span><span className="db-action-label">Add Faculty</span></div>
        </div>
        {/* Row 1, Column 2 */}
        <div className="db-action-card" onClick={() => navigate('/buildings', { state: { openForm: true } })}>
          <div className="db-action-icon-wrapper"><div className="db-action-icon-circle">{quickActions[1].icon}</div></div>
          <div className="db-action-text"><span className="db-action-sub">Nearby</span><span className="db-action-label">Add Building</span></div>
        </div>
        {/* Row 1, Column 3 */}
        <div className="db-action-card" onClick={() => navigate('/halls-labs', { state: { openForm: true } })}>
          <div className="db-action-icon-wrapper"><div className="db-action-icon-circle">{quickActions[2].icon}</div></div>
          <div className="db-action-text"><span className="db-action-sub">Nearby</span><span className="db-action-label">Add Halls/Labs</span></div>
        </div>

        {/* Vertical Spanning Block - Column 4, now Searches by Building */}
        <div className="db-placeholder-block grid-span-2-row">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
            <span className="db-block-title" style={{ margin: 0 }}>Searches by Building</span>
            <select 
              value={timeframe} 
              onChange={(e) => setTimeframe(e.target.value)}
              className="db-filter-select"
              style={{
                background: '#1c1c1e',
                color: '#888',
                border: '1px solid #333',
                borderRadius: '6px',
                fontSize: '10px',
                padding: '2px 4px',
                outline: 'none',
                cursor: 'pointer'
              }}
            >
              <option value="day">Day</option>
              <option value="week">Week</option>
              <option value="month">Month</option>
            </select>
          </div>
          <div style={{ width: '100%', height: 'calc(100% - 30px)' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={searchesByBuilding} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#333" />
                <XAxis type="number" hide />
                <YAxis dataKey="name" type="category" axisLine={false} tickLine={false} tick={{ fontSize: 9, fill: '#888' }} width={70} />
                <Tooltip
                  cursor={{ fill: 'rgba(255,255,255,0.05)' }}
                  contentStyle={{ background: '#1c1c1e', border: '1px solid #444', borderRadius: '8px', color: '#fff' }}
                />
                <Bar dataKey="searches" fill="#818cf8" radius={[0, 4, 4, 0]} barSize={12} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Row 2, Column 1 */}
        <div className="db-action-card" onClick={() => navigate('/users', { state: { openForm: true } })}>
          <div className="db-action-icon-wrapper"><div className="db-action-icon-circle">{quickActions[3].icon}</div></div>
          <div className="db-action-text"><span className="db-action-sub">Manage</span><span className="db-action-label">Add User</span></div>
        </div>

        {/* Horizontal Spanning Block - Row 2, now Searches per Day as LineChart */}
        <div className="db-placeholder-block grid-span-2-col">
          <span className="db-block-title">Searches per Day</span>
          <div style={{ width: '100%', height: 'calc(100% - 20px)' }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={searchesPerDay} margin={{ top: 5, right: 20, left: -20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#333" />
                <XAxis 
                  dataKey="name" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 9, fill: '#888' }} 
                />
                <YAxis 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 9, fill: '#888' }} 
                />
                <Tooltip
                  contentStyle={{ background: '#1c1c1e', border: '1px solid #444', borderRadius: '8px', color: '#fff', fontSize: '10px' }}
                  itemStyle={{ color: '#818cf8' }}
                />
                <Line 
                    type="monotone" 
                    dataKey="searches" 
                    stroke="#818cf8" 
                    strokeWidth={3} 
                    dot={{ r: 3, fill: '#818cf8', strokeWidth: 0 }} 
                    activeDot={{ r: 5, strokeWidth: 0 }} 
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
