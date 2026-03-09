import { useState, useEffect } from 'react';
import { FaSave, FaTimes, FaUpload } from 'react-icons/fa';

const FloorForm = ({ floor, onSave, onCancel }) => {
    const [formData, setFormData] = useState({
        name: '',
        description: '',
        floorNumber: '',
        mapFileName: null,
        mapFileObject: null, // the actual File object
        svgContent: null, // the raw SVG text
        svgMapUrl: null // Existing URL if any
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (floor) {
            setFormData({
                name: floor.name || '',
                description: floor.description || '',
                floorNumber: floor.floorNumber || '',
                mapFileName: (floor.svgMapUrl || floor.svgContent) ? 'Existing Map' : null,
                mapFileObject: null,
                svgContent: floor.svgContent || null,
                svgMapUrl: floor.svgMapUrl || null
            });
        }
    }, [floor]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
        setError('');
    };

    const handleFileChange = (e) => {
        const file = e.target.files && e.target.files[0];
        if (file) {
            console.log('Selected file:', file.name, 'Type:', file.type);

            const isSvg = file.type.includes('svg') ||
                file.name.toLowerCase().endsWith('.svg') ||
                file.type === 'image/svg+xml';

            if (!isSvg) {
                setError('Please upload a valid SVG file');
                return;
            }

            // Read file as text for Firestore fallback
            const reader = new FileReader();
            reader.onload = (event) => {
                const content = event.target.result;
                setFormData(prev => ({
                    ...prev,
                    mapFileName: file.name,
                    mapFileObject: file,
                    svgContent: content
                }));
            };
            reader.onerror = () => {
                setError('Failed to read file content');
            };
            reader.readAsText(file);

            setError('');
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (formData.floorNumber === '') {
            setError('Floor number is required');
            return;
        }

        setLoading(true);
        try {
            await onSave({ ...floor, ...formData });
        } catch (err) {
            setError(err.message || 'Failed to save floor. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="card" style={{ maxWidth: '600px', margin: '0 auto', padding: '2rem', background: 'white', borderRadius: '0.5rem', boxShadow: 'var(--shadow)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h2 style={{ fontSize: '1.5rem', fontWeight: 700 }}>
                    {floor ? 'Edit Floor' : 'Add New Floor'}
                </h2>
                <button type="button" onClick={onCancel} className="btn" style={{ background: 'transparent', color: 'var(--muted-gray)' }}>
                    <FaTimes size={20} />
                </button>
            </div>

            {error && (
                <div style={{
                    padding: '1rem',
                    marginBottom: '1rem',
                    background: '#fee',
                    border: '1px solid #fcc',
                    borderRadius: '0.375rem',
                    color: '#c33'
                }}>
                    {error}
                </div>
            )}

            <form onSubmit={handleSubmit}>
                <div style={{ display: 'flex', gap: '1rem', marginBottom: '1rem' }}>
                    <div className="form-group" style={{ flex: 1, marginBottom: 0 }}>
                        <label>Floor Number *</label>
                        <input
                            type="number"
                            name="floorNumber"
                            className="form-control"
                            value={formData.floorNumber}
                            onChange={handleChange}
                            required
                            placeholder="e.g. 1"
                        />
                    </div>
                    <div className="form-group" style={{ flex: 2, marginBottom: 0 }}>
                        <label>Floor Name</label>
                        <input
                            type="text"
                            name="name"
                            className="form-control"
                            value={formData.name}
                            onChange={handleChange}
                            placeholder="e.g. Ground Floor"
                        />
                    </div>
                </div>

                <div className="form-group">
                    <label>Description / Primary Functions</label>
                    <textarea
                        name="description"
                        className="form-control"
                        value={formData.description}
                        onChange={handleChange}
                        rows="3"
                        placeholder="e.g. Admin Offices, Main Lobby"
                        style={{ resize: 'vertical' }}
                    />
                </div>

                <div className="form-group">
                    <label>Floor Map (SVG only)</label>
                    <div style={{ border: '2px dashed var(--border-color)', borderRadius: '0.5rem', padding: '2rem', textAlign: 'center', background: '#f8fafc', cursor: 'pointer', position: 'relative' }}>
                        <input
                            type="file"
                            accept=".svg,image/svg+xml"
                            onChange={handleFileChange}
                            style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', opacity: 0, cursor: 'pointer' }}
                        />
                        <FaUpload size={24} color="var(--gray-color)" style={{ marginBottom: '0.5rem' }} />
                        <div style={{ fontWeight: 600, color: 'var(--dark-color)' }}>
                            {formData.mapFileName ? formData.mapFileName : 'Click to upload SVG map file'}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--muted-gray)' }}>Supports SVG format only</div>
                    </div>
                </div>

                <div style={{ display: 'flex', gap: '1rem', marginTop: '2rem' }}>
                    <button type="button" onClick={onCancel} className="btn btn-outline" style={{ flex: 1 }}>
                        Cancel
                    </button>
                    <button type="submit" disabled={loading} className="btn btn-primary" style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', opacity: loading ? 0.6 : 1 }}>
                        <FaSave /> {loading ? 'Saving...' : 'Save Floor'}
                    </button>
                </div>
            </form>
        </div>
    );
};

export default FloorForm;
