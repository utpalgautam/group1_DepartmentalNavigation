import { useState, useEffect, useRef } from 'react';

const FacultyForm = ({ faculty, buildings = [], onSave, onCancel }) => {
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        role: '',
        cabin: '',
        building: '',
        floor: '',
        imageUrl: '',
        imageFile: null,
        _localPreview: null
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const fileInputRef = useRef(null);

    const isEdit = !!faculty;

    useEffect(() => {
        if (faculty) {
            setFormData({
                name: faculty.name || '',
                email: faculty.email || '',
                role: faculty.role || '',
                cabin: faculty.cabin || '',
                building: faculty.building || '',
                floor: faculty.floor || '',
                imageUrl: faculty.imageUrl || '',
                imageFile: null,
                _localPreview: null
            });
        }
    }, [faculty]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
        setError('');
    };

    const handleFileChange = (e) => {
        const file = e.target.files?.[0];
        if (!file) return;

        // Basic validation
        if (!file.type.startsWith('image/')) {
            setError('Please upload a valid image file');
            return;
        }
        if (file.size > 5 * 1024 * 1024) {
            setError('Image must be under 5MB');
            return;
        }

        const previewUrl = URL.createObjectURL(file);
        setFormData(prev => ({
            ...prev,
            imageFile: file,
            _localPreview: previewUrl
        }));
        setError('');
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            await onSave({ ...formData, id: faculty ? faculty.id : undefined });
        } catch (err) {
            setError(err.message || 'Failed to save faculty. Please check your connection.');
            setLoading(false);
        }
    };

    const triggerUpload = () => {
        fileInputRef.current?.click();
    };

    const displayImage = formData._localPreview || formData.imageUrl;

    return (
        <form onSubmit={handleSubmit} style={{ width: '100%' }}>
            {error && (
                <div style={{ padding: '1rem', marginBottom: '1.5rem', background: '#fee', border: '1px solid #fcc', borderRadius: '0.5rem', color: '#c33' }}>
                    {error}
                </div>
            )}

            <div className="fac-form-card">

                {/* 1. Left Column: Circular Photo Upload */}
                <div className="fac-upload-block">
                    <div className="fac-upload-circle" onClick={triggerUpload}>
                        {displayImage ? (
                            <img src={displayImage} alt="Profile Preview" />
                        ) : (
                            <svg width="60" height="60" viewBox="0 0 24 24" fill="none" stroke="#b1bbcb" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                <circle cx="12" cy="7" r="4"></circle>
                            </svg>
                        )}
                        <input
                            type="file"
                            accept="image/*"
                            ref={fileInputRef}
                            onChange={handleFileChange}
                            style={{ display: 'none' }}
                        />
                    </div>
                    <div className="fac-upload-meta">
                        <div className="fac-upload-title">Profile Photo</div>
                        <div className="fac-upload-subtitle">JPG, PNG, Max 5MB</div>
                        <button type="button" className="fac-upload-btn" onClick={triggerUpload}>
                            Upload Image
                        </button>
                    </div>
                </div>

                {/* 2. Right Column: Form Inputs */}
                <div className="fac-form-fields">
                    <div className="fac-form-group">
                        <label className="fac-label">Full Name</label>
                        <input
                            type="text"
                            name="name"
                            className="fac-input"
                            value={formData.name}
                            onChange={handleChange}
                            required
                            placeholder="e.g. Dr. John Green"
                        />
                    </div>

                    <div className="fac-form-group">
                        <label className="fac-label">E-mail</label>
                        <input
                            type="email"
                            name="email"
                            className="fac-input"
                            value={formData.email}
                            onChange={handleChange}
                            placeholder="e.g. john@university.edu"
                        />
                    </div>

                    <div className="fac-form-group">
                        <label className="fac-label">Designation</label>
                        <input
                            type="text"
                            name="role"
                            className="fac-input"
                            value={formData.role}
                            onChange={handleChange}
                            placeholder="e.g. Assistant Professor"
                        />
                    </div>

                    <div className="fac-form-row">
                        <div className="fac-form-group">
                            <label className="fac-label">Select Building</label>
                            <select
                                name="building"
                                className="fac-select"
                                value={formData.building}
                                onChange={handleChange}
                                required
                            >
                                <option value="" disabled>Select Building</option>
                                {buildings.map(b => (
                                    <option key={b.id} value={b.id}>{b.name}</option>
                                ))}
                            </select>
                        </div>
                        <div className="fac-form-group">
                            <label className="fac-label">Select Floor</label>
                            <select
                                name="floor"
                                className="fac-select"
                                value={formData.floor}
                                onChange={handleChange}
                            >
                                <option value="" disabled>Select Floor</option>
                                <option value="0">Ground Floor</option>
                                <option value="1">1st Floor</option>
                                <option value="2">2nd Floor</option>
                                <option value="3">3rd Floor</option>
                                <option value="4">4th Floor</option>
                                <option value="5">5th Floor</option>
                            </select>
                        </div>
                    </div>

                    <div className="fac-form-group">
                        <label className="fac-label">Cabin/Office Number</label>
                        <input
                            type="text"
                            name="cabin"
                            className="fac-input"
                            value={formData.cabin}
                            onChange={handleChange}
                            placeholder="e.g. MB104"
                        />
                    </div>
                </div>
            </div>

            {/* 3. Footer Buttons outside the card */}
            <div className="fac-form-footer" style={{ gridTemplateColumns: isEdit ? '1fr 1fr' : '1fr' }}>
                <button type="submit" className="fac-submit-btn" disabled={loading}>
                    {loading ? 'Saving...' : (isEdit ? 'Save' : 'Save Faculty Member')}
                </button>
                {isEdit && (
                    <button type="button" className="fac-cancel-btn" onClick={onCancel} disabled={loading}>
                        Cancel
                    </button>
                )}
            </div>

        </form>
    );
};

export default FacultyForm;
