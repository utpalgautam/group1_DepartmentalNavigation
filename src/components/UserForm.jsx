import React, { useState, useEffect } from 'react';
import { FaArrowLeft } from 'react-icons/fa';

const UserForm = ({ user, onSave, onCancel }) => {
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        role: 'Student',
        department: '', // equivalent to Branch
        year: '',
        status: 'active'
    });

    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (user) {
            setFormData({
                name: user.name || '',
                email: user.email || '',
                role: user.role || 'Student',
                department: user.department || '',
                year: user.year || '',
                status: user.status || 'active'
            });
        }
    }, [user]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!formData.name || !formData.email) {
            setError('Name and Email are required.');
            return;
        }

        setIsSubmitting(true);
        setError('');
        try {
            await onSave(formData);
        } catch (err) {
            setError(err.message || 'Failed to save user.');
            setIsSubmitting(false);
        }
    };

    const isEditMode = !!user;

    return (
        <div className="user-form-page">
            <div className="user-form-container">
                <form id="userForm" onSubmit={handleSubmit} className="user-form-content">
                    {error && <div className="user-form-error">{error}</div>}

                    <div className="user-form-grid">
                        {/* Full Name */}
                        <div className="user-form-group">
                            <label>Full Name</label>
                            <input
                                type="text"
                                name="name"
                                value={formData.name}
                                onChange={handleChange}
                                placeholder="Dr. John Green"
                                className="user-form-input"
                                required
                            />
                        </div>

                        {/* E-mail */}
                        <div className="user-form-group">
                            <label>E-mail</label>
                            <input
                                type="email"
                                name="email"
                                value={formData.email}
                                onChange={handleChange}
                                placeholder="Dr. John Green"
                                className="user-form-input"
                                required
                            />
                        </div>

                        {/* User Type */}
                        <div className="user-form-group">
                            <label>User Type</label>
                            <div className="user-form-select-wrapper">
                                <select
                                    name="role"
                                    value={formData.role}
                                    onChange={handleChange}
                                    className="user-form-input user-form-select"
                                >
                                    <option value="Student">Student</option>
                                    <option value="Faculty">Faculty</option>
                                    <option value="Staff">Staff</option>
                                    <option value="Admin">Admin</option>
                                </select>
                                <div className="user-form-select-icon">
                                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg>
                                </div>
                            </div>
                        </div>

                        {/* Branch */}
                        <div className="user-form-group">
                            <label>Branch</label>
                            <input
                                type="text"
                                name="department"
                                value={formData.department}
                                onChange={handleChange}
                                placeholder="Dr. John Green"
                                className="user-form-input"
                            />
                        </div>

                        {/* Year */}
                        <div className="user-form-group">
                            <label>Year</label>
                            <input
                                type="text"
                                name="year"
                                value={formData.year}
                                onChange={handleChange}
                                placeholder="Dr. John Green"
                                className="user-form-input"
                            />
                        </div>

                        {/* Status */}
                        <div className="user-form-group">
                            <label>Status</label>
                            <div className="user-form-select-wrapper">
                                <select
                                    name="status"
                                    value={formData.status}
                                    onChange={handleChange}
                                    className="user-form-input user-form-select"
                                >
                                    <option value="active">Active</option>
                                    <option value="inactive">Inactive</option>
                                </select>
                                <div className="user-form-select-icon">
                                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg>
                                </div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>

            {/* Action Footer */}
            <div className="user-form-actions-footer">
                <button
                    type="submit"
                    form="userForm"
                    className="user-form-save-btn"
                    disabled={isSubmitting}
                >
                    {isSubmitting ? 'Saving...' : (isEditMode ? 'Save' : 'Save Faculty Member')}
                </button>
                <button
                    type="button"
                    className="user-form-cancel-btn"
                    onClick={onCancel}
                    disabled={isSubmitting}
                >
                    Cancel
                </button>
            </div>
        </div>
    );
};

export default UserForm;
