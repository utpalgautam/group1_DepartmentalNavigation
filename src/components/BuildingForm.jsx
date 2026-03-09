import { useState, useEffect, useRef } from 'react';
import { FaArrowLeft, FaCloudUploadAlt, FaTimes } from 'react-icons/fa';

/**
 * Reusable Image Upload Zone Component
 */
const ImageUploadZone = ({ label = "Upload Image", fileName, onChange, previewUrl }) => {
    const inputRef = useRef();

    // If we have an existing image URL or a selected file name, show it
    const displayContent = fileName || previewUrl;

    return (
        <div className="bf-upload-box" onClick={() => inputRef.current.click()}>
            <input
                ref={inputRef}
                type="file"
                accept="image/*"
                style={{ display: 'none' }}
                onChange={onChange}
            />
            {displayContent ? (
                <div className="bf-upload-preview">
                    <FaCloudUploadAlt size={22} color="#9aa4af" />
                    <span className="bf-upload-filename">{fileName || 'Existing Image'}</span>
                </div>
            ) : (
                <>
                    <FaCloudUploadAlt size={24} color="#9aa4af" style={{ marginBottom: '0.4rem' }} />
                    <span className="bf-upload-label">{label}</span>
                </>
            )}
        </div>
    );
};

const BuildingForm = ({ building, onSave, onCancel }) => {
    // --- Building Details State ---
    const [formData, setFormData] = useState({
        name: '',
        department: '',
        latitude: '',
        longitude: '',
        totalFloors: '1',
        // Existing DB Image URL
        imageUrl: null,
        // File object to be uploaded
        imageFile: null,
        // Just for UI display
        imageFileName: ''
    });

    // --- Entry Points State ---
    // Default to zero entry points (user clicks "Add entry point" to create one)
    const [entryPoints, setEntryPoints] = useState([]);

    // Temporary state for the "Add Entry Point" mini-form
    const [epForm, setEpForm] = useState({
        label: '',
        latitude: '',
        longitude: '',
        imageUrl: null,
        imageFile: null,
        imageFileName: ''
    });

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    // Load existing building data if we are in "Edit" mode
    useEffect(() => {
        if (building) {
            setFormData({
                name: building.name || '',
                department: building.department || '',
                latitude: building.latitude || '',
                longitude: building.longitude || '',
                totalFloors: building.totalFloors || '1',
                imageUrl: building.imageUrl || null,
                imageFile: null,
                imageFileName: building.imageUrl ? 'Existing Building Photo' : ''
            });
            // Load existing entry points seamlessly
            if (building.entryPoints && building.entryPoints.length > 0) {
                setEntryPoints(building.entryPoints.map(ep => ({
                    ...ep,
                    id: ep.id || `ep-${Date.now()}-${Math.random()}`
                })));
            }
        }
    }, [building]);

    // --- Handlers: Main Building ---
    const handleMainChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
        setError('');
    };

    const handleMainImageSelect = (e) => {
        const file = e.target.files?.[0];
        if (file) {
            setFormData(prev => ({
                ...prev,
                imageFile: file,
                imageFileName: file.name
            }));
        }
    };

    // --- Handlers: Entry Points ---
    const handleEpChange = (e) => {
        const { name, value } = e.target;
        setEpForm(prev => ({ ...prev, [name]: value }));
        setError('');
    };

    const handleEpImageSelect = (e) => {
        const file = e.target.files?.[0];
        if (file) {
            setEpForm(prev => ({ ...prev, imageFile: file, imageFileName: file.name }));
        }
    };

    const wrapAddEntryPoint = () => {
        // Validate ep form
        if (!epForm.label.trim()) { setError('Entry Point Label is required'); return; }
        if (!epForm.latitude || !epForm.longitude) { setError('Entry Point Lat/Lng required'); return; }

        const newEp = {
            id: `ep-${Date.now()}`,
            label: epForm.label,
            latitude: epForm.latitude,
            longitude: epForm.longitude,
            imageFile: epForm.imageFile,
            imageUrl: epForm.imageUrl, // Will be null for new ones
            // Store local UI display reference so we can show it in the list
            _localPreview: epForm.imageFile ? URL.createObjectURL(epForm.imageFile) : null,
            _localFileName: epForm.imageFileName
        };

        setEntryPoints([...entryPoints, newEp]);

        // Clear the mini-form for the next entry point
        setEpForm({ label: '', latitude: '', longitude: '', imageUrl: null, imageFile: null, imageFileName: '' });
        setError('');
    };

    const removeEntryPoint = (indexToRemove) => {
        setEntryPoints(entryPoints.filter((_, idx) => idx !== indexToRemove));
    };


    // --- Submit ---
    const handleSubmit = async () => {
        setError('');

        if (!formData.name.trim()) { setError('Building Name is required'); return; }
        if (!formData.latitude || !formData.longitude) { setError('Building Latitude and Longitude are required'); return; }

        // We require at least one entry point
        if (entryPoints.length === 0) {
            setError('Please add at least one Entry Point');
            return;
        }

        setLoading(true);

        try {
            const submitData = {
                name: formData.name,
                department: formData.department,
                latitude: formData.latitude,
                longitude: formData.longitude,
                totalFloors: formData.totalFloors,
                imageUrl: formData.imageUrl,
                imageFile: formData.imageFile,
                // Strip out the UI-only _local preview properties before sending to service
                entryPoints: entryPoints.map(ep => ({
                    id: ep.id,
                    label: ep.label,
                    latitude: ep.latitude,
                    longitude: ep.longitude,
                    imageUrl: ep.imageUrl,
                    imageFile: ep.imageFile
                }))
            };

            await onSave(submitData);
        } catch (err) {
            console.error(err);
            setError(err.message || 'Failed to save building details');
            setLoading(false);
        }
    };


    // --- UI Render ---
    const isEditing = !!building;

    return (
        <div className="bf-page">
            {/* Dynamic Header */}
            <div className="bf-topbar">
                <div className="bf-topbar-left">
                    <button className="bf-back-btn" onClick={onCancel} title="Cancel and go back">
                        <FaArrowLeft size={14} />
                    </button>
                    <h1 className="bf-page-title">{isEditing ? 'Edit Buildings' : 'Add Buildings'}</h1>
                </div>

                <div className="bf-topbar-right">
                    <div className="buildings-search-wrapper">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="buildings-search-icon" style={{ position: 'absolute', left: '1.2rem', top: '50%', transform: 'translateY(-50%)' }}>
                            <circle cx="11" cy="11" r="8"></circle>
                            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                        </svg>
                        <input className="buildings-search-input" style={{ paddingLeft: '2.8rem' }} placeholder="Search..." />
                    </div>
                    <div className="buildings-avatar">
                        <div className="buildings-avatar-circle">AR</div>
                    </div>
                </div>
            </div>

            {error && <div className="bf-alert bf-alert-error">{error}</div>}

            <div className="bf-layout">

                {/* ========================================================= */}
                {/* LEFT PANEL: Building Details                              */}
                {/* ========================================================= */}
                <div className="bf-panel bf-left-panel">
                    <h2 className="bf-panel-title">{isEditing ? 'Edit Building Details' : 'Building Details'}</h2>

                    <div className="bf-form-group">
                        <label className="bf-label">Building Name</label>
                        <input
                            type="text"
                            name="name"
                            className="bf-input"
                            placeholder="e.g. Main Building"
                            value={formData.name}
                            onChange={handleMainChange}
                        />
                    </div>

                    <div className="bf-form-group">
                        <label className="bf-label">Department</label>
                        <div className="bf-select-wrapper">
                            <select
                                name="department"
                                className="bf-select"
                                value={formData.department}
                                onChange={handleMainChange}
                            >
                                <option value="" disabled>Select Department</option>
                                <option value="Computer Science and Engineering">Computer Science and Engineering</option>
                                <option value="Electrical Engineering">Electrical Engineering</option>
                                <option value="Mechanical Engineering">Mechanical Engineering</option>
                                <option value="Civil Engineering">Civil Engineering</option>
                                <option value="Applied Sciences">Applied Sciences</option>
                                <option value="Administration">Administration</option>
                                <option value="Library">Library</option>
                                <option value="Other">Other</option>
                            </select>
                            <span className="bf-select-caret">▾</span>
                        </div>
                    </div>

                    <div className="bf-row">
                        <div className="bf-form-group">
                            <label className="bf-label">Latitude</label>
                            <input
                                type="number"
                                step="any"
                                name="latitude"
                                className="bf-input"
                                placeholder="0.00000"
                                value={formData.latitude}
                                onChange={handleMainChange}
                            />
                        </div>
                        <div className="bf-form-group">
                            <label className="bf-label">Longitude</label>
                            <input
                                type="number"
                                step="any"
                                name="longitude"
                                className="bf-input"
                                placeholder="0.00000"
                                value={formData.longitude}
                                onChange={handleMainChange}
                            />
                        </div>
                    </div>

                    <div className="bf-row">
                        <div className="bf-form-group">
                            <label className="bf-label">Total Floors</label>
                            <input
                                type="number"
                                name="totalFloors"
                                className="bf-input"
                                placeholder="e.g. 3"
                                min="1"
                                value={formData.totalFloors}
                                onChange={handleMainChange}
                            />
                        </div>
                    </div>

                    <div className="bf-form-group bf-photo-group">
                        <label className="bf-label">Building Photo</label>
                        <ImageUploadZone
                            label="Upload Image"
                            fileName={formData.imageFileName}
                            previewUrl={formData.imageUrl}
                            onChange={handleMainImageSelect}
                        />
                    </div>
                </div>


                {/* ========================================================= */}
                {/* RIGHT PANEL: Entry Points                                 */}
                {/* ========================================================= */}
                <div className="bf-panel bf-right-panel">
                    <h2 className="bf-panel-title">{isEditing ? 'Edit Entry Points' : 'Add Entry Points'}</h2>

                    {/* Entry Point Input Form */}
                    <div className="bf-ep-builder">
                        <div className="bf-ep-builder-left">
                            <div className="bf-form-group">
                                <label className="bf-label">Label</label>
                                <input
                                    type="text"
                                    name="label"
                                    className="bf-input"
                                    placeholder="e.g. Center"
                                    value={epForm.label}
                                    onChange={handleEpChange}
                                />
                            </div>
                            <div className="bf-row" style={{ marginTop: '0.8rem' }}>
                                <div className="bf-form-group">
                                    <label className="bf-label">Latitude</label>
                                    <input
                                        type="number"
                                        step="any"
                                        name="latitude"
                                        className="bf-input"
                                        placeholder="0.00000"
                                        value={epForm.latitude}
                                        onChange={handleEpChange}
                                    />
                                </div>
                                <div className="bf-form-group">
                                    <label className="bf-label">Longitude</label>
                                    <input
                                        type="number"
                                        step="any"
                                        name="longitude"
                                        className="bf-input"
                                        placeholder="0.00000"
                                        value={epForm.longitude}
                                        onChange={handleEpChange}
                                    />
                                </div>
                            </div>
                        </div>
                        <div className="bf-ep-builder-right">
                            <ImageUploadZone
                                label="Upload Image"
                                fileName={epForm.imageFileName}
                                onChange={handleEpImageSelect}
                            />
                        </div>
                    </div>

                    <button className="bf-btn-dark bf-add-ep-btn" onClick={wrapAddEntryPoint}>
                        Add entry point
                    </button>

                    <hr className="bf-divider" />

                    {/* List of Added Entry Points */}
                    <div className="bf-ep-list">
                        {entryPoints.map((ep, idx) => {
                            // Determine preview image source
                            const thumbSrc = ep._localPreview || ep.imageUrl;

                            return (
                                <div key={ep.id} className="bf-ep-card">
                                    <div className="bf-ep-card-info">
                                        <div className="bf-ep-meta">
                                            <span className="bf-ep-label-title">Label</span>
                                            <span className="bf-ep-label-val">{ep.label}</span>
                                        </div>
                                        <div className="bf-ep-coords">
                                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                                                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                                                <circle cx="12" cy="10" r="3"></circle>
                                            </svg>
                                            <div className="bf-ep-coords-text">
                                                <div>{Number(ep.latitude).toFixed(6)}</div>
                                                <div>{Number(ep.longitude).toFixed(6)}</div>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="bf-ep-card-right">
                                        {thumbSrc ? (
                                            <img src={thumbSrc} alt={ep.label} className="bf-ep-thumb" />
                                        ) : (
                                            <div className="bf-ep-thumb-placeholder" />
                                        )}
                                        <button className="bf-ep-remove" onClick={() => removeEntryPoint(idx)}>
                                            <FaTimes size={10} color="#111" />
                                        </button>
                                    </div>
                                </div>
                            );
                        })}

                        {entryPoints.length === 0 && (
                            <div style={{ color: '#9aa4af', fontSize: '0.85rem', textAlign: 'center', marginTop: '1rem' }}>
                                No entry points added yet.
                            </div>
                        )}
                    </div>

                </div>

            </div>

            {/* Main Save Action spanning full width below panels */}
            <button
                className="bf-btn-dark bf-save-main-btn"
                onClick={handleSubmit}
                disabled={loading}
            >
                {loading ? 'Saving securely...' : 'Save Building Details'}
            </button>

        </div>
    );
};

export default BuildingForm;
