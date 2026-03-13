import { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import Header from '../components/Header';
import Pagination from '../components/Pagination';
import { fetchAllUsers, updateUserStatus, resetUserPassword, addUser, updateUser, deleteUser } from '../services/userService';
import UserForm from '../components/UserForm';

const UserManagementPage = () => {
  const location = useLocation();
  const [viewState, setViewState] = useState(location.state?.openForm ? 'add' : 'list');
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortAsc, setSortAsc] = useState(true);
  const [selectedUser, setSelectedUser] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 4;

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const data = await fetchAllUsers();
      setUsers(data);
    } catch (err) {
      console.error(err);
      setError('Failed to fetch users. Please refresh the page.');
    } finally {
      setLoading(false);
    }
  };

  const getFilteredAndSortedUsers = () => {
    let filtered = (users || []).filter(user => {
      const name = user?.name || '';
      const email = user?.email || '';
      const matchesSearch =
        email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        name.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesSearch;
    });

    filtered.sort((a, b) => {
      const aName = a.name || '';
      const bName = b.name || '';
      return sortAsc ? aName.localeCompare(bName) : bName.localeCompare(aName);
    });

    return filtered;
  };

  const filteredUsers = getFilteredAndSortedUsers();

  const handleAddUserClick = () => {
    setSelectedUser(null);
    setViewState('add');
  };

  const handleEditUserClick = (user) => {
    setSelectedUser(user);
    setViewState('edit');
  };

  const handleSaveUser = async (formData) => {
    try {
      if (viewState === 'add') {
        await addUser(formData);
      } else {
        await updateUser(selectedUser.id, formData);
      }
      await loadUsers();
      setViewState('list');
      setSelectedUser(null);
    } catch (err) {
      console.error('Error saving user:', err);
      throw err;
    }
  };

  const handleCancelForm = () => {
    setViewState('list');
    setSelectedUser(null);
  };

  const handleDeleteUserClick = async (user) => {
    if (window.confirm(`Are you sure you want to delete ${user.name}?`)) {
      try {
        await deleteUser(user.id);
        await loadUsers();
      } catch (err) {
        console.error('Error deleting user:', err);
        setError('Failed to delete user.');
      }
    }
  };

  const handleResetPasswordClick = async (user) => {
    try {
      await resetUserPassword(user.email);
      alert(`Password reset link sent to ${user.email}`);
    } catch (err) {
      console.error('Error resetting password:', err);
    }
  };

  if (viewState === 'add' || viewState === 'edit') {
    const pageTitle = viewState === 'add' ? 'Add New User' : 'Edit User';
    return (
      <div className="user-page">
        <Header
          title={pageTitle}
          searchDisabled={true}
          onBack={handleCancelForm}
        />
        <UserForm
          user={selectedUser}
          onSave={handleSaveUser}
          onCancel={handleCancelForm}
        />
      </div>
    );
  }

  return (
    <div className="user-page">
      <Header
        title="User Management"
        searchTerm={searchQuery}
        onSearchChange={e => {
          setSearchQuery(e.target.value);
          setCurrentPage(1);
        }}
      />

      <div className="user-toolbar">
        <button className="user-sort-btn" onClick={() => setSortAsc(!sortAsc)}>
          Sort {sortAsc ? '↑↓' : '↓↑'}
        </button>
        <button className="user-add-btn" onClick={handleAddUserClick}>
          <span>+</span> User
        </button>
      </div>

      {error && <div style={{ color: 'red', marginBottom: '1rem' }}>{error}</div>}

      <div className="user-table-container">
        <table className="user-table">
          <thead>
            <tr>
              <th>User Name</th>
              <th>Branch</th>
              <th>Type</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="5" style={{ textAlign: 'center' }}>Loading...</td></tr>
            ) : filteredUsers.length === 0 ? (
              <tr><td colSpan="5" style={{ textAlign: 'center' }}>No users found.</td></tr>
            ) : (
              filteredUsers
                .slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage)
                .map(user => (
                <tr key={user.id}>
                  <td>
                    <div className="user-name-cell">
                      <div className="user-avatar-dark">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                          <circle cx="12" cy="7" r="4"></circle>
                        </svg>
                      </div>
                      <div>
                        <div className="user-name-text">{user.name || 'Unknown User'}</div>
                        <div className="user-email-text">{user.email}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span className="user-branch-text">{user.department || 'N/A'}</span>
                  </td>
                  <td>
                    <span className="user-pill user-pill-blue">{user.role || 'Student'}</span>
                  </td>
                  <td>
                    <span className={`user-pill ${(user.status || 'inactive') === 'active' ? 'user-pill-green' : 'user-pill-red'}`}>
                      {(user.status || 'Inactive').charAt(0).toUpperCase() + (user.status || 'inactive').slice(1)}
                    </span>
                  </td>
                  <td>
                    <div className="user-action-group">
                      <button className="user-pill user-pill-purple" onClick={() => handleResetPasswordClick(user)}>
                        Reset
                      </button>
                      <button className="user-pill user-pill-yellow" onClick={() => handleEditUserClick(user)}>
                        Modify
                      </button>
                      <button className="user-icon-btn user-btn-black" onClick={() => handleDeleteUserClick(user)}>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <Pagination 
        currentPage={currentPage}
        totalItems={filteredUsers.length}
        itemsPerPage={itemsPerPage}
        onPageChange={setCurrentPage}
      />
    </div>
  );
};

export default UserManagementPage;