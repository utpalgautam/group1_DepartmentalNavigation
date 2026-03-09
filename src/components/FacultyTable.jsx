import { FaTrash } from 'react-icons/fa';

const FacultyTable = ({ facultyData, buildings = [], onEdit, onDelete }) => {
  const getBuildingName = (id) => buildings.find(b => b.id === id)?.name || id;

  const getLocationString = (faculty) => {
    const parts = [];
    if (faculty.building) parts.push(getBuildingName(faculty.building));
    if (faculty.floor) parts.push(`Floor ${faculty.floor}`);
    if (faculty.cabin) parts.push(faculty.cabin);
    return parts.join(', ') || 'Unassigned';
  };

  if (!facultyData || facultyData.length === 0) {
    return (
      <div style={{ textAlign: 'center', padding: '3rem', color: '#9aa4af', fontStyle: 'italic' }}>
        No faculty members found.
      </div>
    );
  }

  return (
    <div>
      <div className="fac-table-wrapper">
        {/* Table Header block */}
        <div className="fac-table-header">
          <div>Faculty Member Name</div>
          <div>Department</div>
          <div>Cabin</div>
          <div style={{ textAlign: 'center' }}>Action</div>
        </div>

        {/* Table Rows */}
        {facultyData.map((faculty) => (
          <div key={faculty.id} className="fac-table-row">
            {/* 1. Name and Avatar */}
            <div className="fac-table-cell fac-cell-user">
              {faculty.imageUrl ? (
                <img src={faculty.imageUrl} alt={faculty.name} className="fac-avatar" />
              ) : (
                <div className="fac-avatar" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#9aa4af', fontSize: '0.9rem', fontWeight: 'bold' }}>
                  {faculty.name.substring(0, 2).toUpperCase()}
                </div>
              )}
              <div style={{ display: 'flex', flexDirection: 'column' }}>
                <span className="fac-cell-strong">{faculty.name}</span>
                <span style={{ fontSize: '0.75rem', color: '#9aa4af', marginTop: '0.1rem' }}>
                  {faculty.role || 'Faculty'}
                </span>
              </div>
            </div>

            {/* 2. Department */}
            <div className="fac-table-cell" style={{ color: '#9aa4af' }}>
              {/* Extract department from building name or default fallback */}
              {faculty.department || 'Computer Science'}
            </div>

            {/* 3. Cabin / Location */}
            <div className="fac-table-cell" style={{ color: '#9aa4af' }}>
              {getLocationString(faculty)}
            </div>

            {/* 4. Actions */}
            <div className="fac-table-cell" style={{ gap: '0.75rem', justifyContent: 'center' }}>
              <button className="fac-action-pill" onClick={(e) => { e.stopPropagation(); onEdit(faculty); }}>
                Edit Profile
              </button>
              <button className="fac-action-icon" onClick={(e) => { e.stopPropagation(); onDelete(faculty.id); }}>
                <FaTrash size={16} />
              </button>
            </div>
          </div>
        ))}
      </div>

      <div style={{ padding: '1rem', color: '#9aa4af', fontSize: '0.85rem' }}>
        Showing {facultyData.length} records
      </div>
    </div>
  );
};

export default FacultyTable;