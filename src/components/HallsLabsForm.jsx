import { useState, useRef, useEffect } from 'react';
import { FaCloudUploadAlt } from 'react-icons/fa';

const HallsLabsForm = ({ item, buildings = [], onSave, onCancel }) => {
    const fileInputRef = useRef(null);

    const [formData, setFormData] = useState({
        name: '',
        type: 'LECTURE HALL',
        category: 'HALL',
        building: '',
        floor: '',
        capacity: '',
        status: 'ACTIVE',
        contactPerson: '',
        department: '',
        incharge: '',
        inchargeEmail: '',
        timing: {},
        mapUrl: '',
        mapFile: null,
        _localPreview: ''
    });

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (item) {
            setFormData({
                name: item.name || '',
                type: item.type || (item.category === 'LAB' ? 'LABORATORY' : 'LECTURE HALL'),
                category: item.category || 'HALL',
                building: item.building || '',
                floor: item.floor || '',
                capacity: item.capacity || '',
                status: item.status || 'ACTIVE',
                contactPerson: item.contactPerson || '',
                department: item.department || '',
                incharge: item.incharge || '',
                inchargeEmail: item.inchargeEmail || '',
                timing: item.timing || {},
                mapUrl: item.mapUrl || '',
                mapFile: null,
                _localPreview: ''
            });
        }
    }, [item]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleCategoryChange = (category) => {
        setFormData(prev => ({
            ...prev,
            category,
            type: category === 'LAB' ? 'LABORATORY' : 'LECTURE HALL'
        }));
    };

    const handleImageChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            if (file.size > 5 * 1024 * 1024) {
                setError("Image cannot exceed 5MB.");
                return;
            }
            setFormData(prev => ({
                ...prev,
                mapFile: file,
                _localPreview: URL.createObjectURL(file)
            }));
            setError('');
        }
    };

    const triggerUpload = () => {
        fileInputRef.current?.click();
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const dataToSave = { ...formData };
            if (item) dataToSave.id = item.id;
            await onSave(dataToSave);
        } catch (err) {
            setError(err.message || 'Failed to save. Please check your connection.');
            setLoading(false);
        }
    };

    const isLab = formData.category === 'LAB';
    const displayMap = formData._localPreview || formData.mapUrl;

    const renderInputFields = () => (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
            <div className="hl-form-grid">
                <div className="hl-form-group">
                    <label>Name</label>
                    <input
                        type="text"
                        name="name"
                        className="hl-input-pill"
                        value={formData.name}
                        onChange={handleChange}
                        placeholder={isLab ? "System Software Laboratory" : "Seminar Hall"}
                        required
                    />
                </div>
                <div className="hl-form-group">
                    <label>Type</label>
                    <select name="type" className="hl-input-pill" value={formData.type} onChange={handleChange}>
                        {isLab ? (
                            <option value="LABORATORY">Laboratory</option>
                        ) : (
                            <>
                                <option value="LECTURE HALL">Lecture Hall</option>
                                <option value="SEMINAR ROOM">Seminar Room</option>
                                <option value="AUDITORIUM">Auditorium</option>
                            </>
                        )}
                    </select>
                </div>
            </div>

            <div className="hl-form-grid">
                <div className="hl-form-group">
                    <label>Building</label>
                    <select
                        name="building"
                        className="hl-input-pill"
                        value={formData.building}
                        onChange={handleChange}
                        required
                    >
                        <option value="">Select Building</option>
                        {buildings.map(b => (
                            <option key={b.id} value={b.id}>{b.name}</option>
                        ))}
                    </select>
                </div>
                <div className="hl-form-group">
                    <label>Floor</label>
                    <input
                        type="text"
                        name="floor"
                        className="hl-input-pill"
                        value={formData.floor}
                        onChange={handleChange}
                        placeholder="Select Floor"
                    />
                </div>
            </div>

            <div className="hl-form-grid">
                <div className="hl-form-group">
                    <label>Capacity</label>
                    <input
                        type="number"
                        name="capacity"
                        className="hl-input-pill"
                        value={formData.capacity}
                        onChange={handleChange}
                        placeholder="45"
                    />
                </div>
                <div className="hl-form-group">
                    <label>Status</label>
                    <select name="status" className="hl-input-pill" value={formData.status} onChange={handleChange}>
                        <option value="ACTIVE">Active</option>
                        <option value="MAINTENANCE">Maintenance</option>
                        <option value="CLOSED">Closed</option>
                    </select>
                </div>
            </div>

            {isLab === false && (
                <div className="hl-form-group">
                    <label>Contact Person</label>
                    <input
                        type="text"
                        name="contactPerson"
                        className="hl-input-pill hl-input-full"
                        value={formData.contactPerson}
                        onChange={handleChange}
                        placeholder="Dr. Ramesh Kumar"
                    />
                </div>
            )}

            {isLab && (
                <>
                    <div className="hl-form-group">
                        <label>Department</label>
                        <input
                            type="text"
                            name="department"
                            className="hl-input-pill hl-input-full"
                            value={formData.department}
                            onChange={handleChange}
                            placeholder="Computer Science"
                        />
                    </div>
                    <div className="hl-form-grid">
                        <div className="hl-form-group">
                            <label>Lab In-charge</label>
                            <input
                                type="text"
                                name="incharge"
                                className="hl-input-pill"
                                value={formData.incharge}
                                onChange={handleChange}
                                placeholder="Mr. Anil Singh"
                            />
                        </div>
                        <div className="hl-form-group">
                            <label>In-charge Email</label>
                            <input
                                type="email"
                                name="inchargeEmail"
                                className="hl-input-pill"
                                value={formData.inchargeEmail}
                                onChange={handleChange}
                                placeholder="anil@university.edu"
                            />
                        </div>
                    </div>
                </>
            )}
        </div>
    );

    const renderUploadZone = () => (
        <div className="hl-upload-zone" onClick={triggerUpload}>
            <input
                type="file"
                accept="image/png, image/jpeg, image/webp"
                className="hl-hidden-input"
                ref={fileInputRef}
                onChange={handleImageChange}
            />
            {displayMap ? (
                <img src={displayMap} alt="Map Preview" className="hl-upload-preview" />
            ) : (
                <>
                    <FaCloudUploadAlt size={32} className="hl-upload-icon" />
                    <span className="hl-upload-label">Upload Map</span>
                </>
            )}
        </div>
    );

    return (
        <form onSubmit={handleSubmit} style={{ width: '100%', margin: '0 auto' }}>
            {error && (
                <div style={{ padding: '1rem', marginBottom: '1.5rem', background: '#fee', border: '1px solid #fcc', borderRadius: '0.5rem', color: '#c33' }}>
                    {error}
                </div>
            )}

            <div className="hl-form-container">
                <div className={`hl-form-inner-box ${item ? 'dashed' : ''}`}>
                    {!item && (
                        <div className="hl-type-toggle">
                            <button
                                type="button"
                                className={`hl-type-btn ${!isLab ? 'active' : 'inactive'}`}
                                onClick={() => handleCategoryChange('HALL')}
                            >
                                Add New Hall
                            </button>
                            <button
                                type="button"
                                className={`hl-type-btn ${isLab ? 'active' : 'inactive'}`}
                                onClick={() => handleCategoryChange('LAB')}
                            >
                                Add New Lab
                            </button>
                        </div>
                    )}

                    {item && (
                        <h2 style={{ fontSize: '1.8rem', fontWeight: 600, marginBottom: '2.5rem', color: '#111' }}>
                            {formData.name || (isLab ? 'Edit Lab' : 'Edit Hall')}
                        </h2>
                    )}

                    <div style={{
                        display: 'grid',
                        gridTemplateColumns: item ? '1fr 2fr' : '2fr 1fr',
                        gap: '3rem',
                        alignItems: 'start'
                    }}>
                        {item ? (
                            <>
                                {renderUploadZone()}
                                {renderInputFields()}
                            </>
                        ) : (
                            <>
                                {renderInputFields()}
                                {renderUploadZone()}
                            </>
                        )}
                    </div>
                </div>

                <div className="hl-form-actions" style={{ justifyContent: item ? 'flex-start' : 'center', width: '100%' }}>
                    <button
                        type="submit"
                        className="hl-btn-save"
                        disabled={loading}
                        style={{ flex: item ? '0 1 250px' : '1' }}
                    >
                        {loading ? 'Saving...' : (item ? 'Save' : `Save ${isLab ? 'Lab' : 'Hall'}`)}
                    </button>
                    {item && (
                        <button
                            type="button"
                            className="hl-btn-cancel"
                            onClick={onCancel}
                            disabled={loading}
                            style={{ flex: '0 1 250px' }}
                        >
                            Cancel
                        </button>
                    )}
                </div>
            </div>
        </form>
    );
};

export default HallsLabsForm;
