import { useState, useEffect, useRef } from 'react';
import { FaArrowLeft, FaLayerGroup, FaCloudUploadAlt, FaMapMarkerAlt } from 'react-icons/fa';
import { fetchFloors, addFloor, deleteFloor } from '../services/floorService';
import { updateBuilding } from '../services/buildingService';

// ── helper: read SVG file as text ──────────────────────────────────────────
const readSvgFile = (file) =>
    new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = (e) => resolve(e.target.result);
        reader.onerror = reject;
        reader.readAsText(file);
    });

// ── SVG Viewer (inline render or <img>) ───────────────────────────────────
const SvgViewer = ({ floor }) => {
    if (!floor) {
        return (
            <div className="bd-svgviewer bd-svgviewer--empty">
                <FaLayerGroup size={40} color="#c4cbd6" />
                <span>Select a floor to preview its map</span>
            </div>
        );
    }
    if (!floor.svgContent && !floor.svgMapUrl) {
        return (
            <div className="bd-svgviewer bd-svgviewer--empty">
                <FaLayerGroup size={40} color="#c4cbd6" />
                <span>No map uploaded for Floor {floor.floorNumber}</span>
            </div>
        );
    }
    return (
        <div className="bd-svgviewer">
            {floor.svgContent ? (
                <div
                    className="bd-svgviewer__inner"
                    dangerouslySetInnerHTML={{ __html: floor.svgContent }}
                />
            ) : (
                <img
                    src={floor.svgMapUrl}
                    alt={`Floor ${floor.floorNumber} map`}
                    className="bd-svgviewer__img"
                />
            )}
        </div>
    );
};

// ── File Upload Zone ───────────────────────────────────────────────────────
const UploadZone = ({ fileName, onChange }) => {
    const inputRef = useRef();
    return (
        <div className="bd-upload" onClick={() => inputRef.current.click()}>
            <input
                ref={inputRef}
                type="file"
                accept=".svg,image/svg+xml"
                style={{ display: 'none' }}
                onChange={onChange}
            />
            <FaCloudUploadAlt size={22} color="#9aa4af" />
            <span className="bd-upload__label">
                {fileName || 'Upload Map'}
            </span>
        </div>
    );
};

// ── Main Component ─────────────────────────────────────────────────────────
const BuildingDetails = ({ building, onBack, onEdit }) => {
    const [floors, setFloors] = useState([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('add'); // 'add' | 'edit'
    const [previewFloor, setPreviewFloor] = useState(null);
    const [error, setError] = useState('');

    // Add floor form state
    const [addForm, setAddForm] = useState({ floorNumber: '', name: '', mapFile: null, mapFileName: '', svgContent: null, mapFileObject: null });
    const [addLoading, setAddLoading] = useState(false);
    const [addError, setAddError] = useState('');
    const [addSuccess, setAddSuccess] = useState('');

    // Edit floor form state
    const [editFloorId, setEditFloorId] = useState('');
    const [editForm, setEditForm] = useState({ floorNumber: '', name: '', mapFile: null, mapFileName: '', svgContent: null, mapFileObject: null });
    const [editLoading, setEditLoading] = useState(false);
    const [editError, setEditError] = useState('');
    const [editSuccess, setEditSuccess] = useState('');

    useEffect(() => {
        if (building?.id) loadFloors();
    }, [building]);

    const loadFloors = async () => {
        try {
            setLoading(true);
            const data = await fetchFloors(building.id);
            data.sort((a, b) => a.floorNumber - b.floorNumber);
            setFloors(data);
        } catch (err) {
            setError('Failed to load floors');
        } finally {
            setLoading(false);
        }
    };

    // When user picks a floor for preview
    const handleSelectFloor = (e) => {
        const id = e.target.value;
        const f = floors.find((fl) => fl.id === id);
        setPreviewFloor(f || null);
    };

    // When user picks a floor in the Edit tab
    const handleEditSelect = (e) => {
        const id = e.target.value;
        setEditFloorId(id);
        const f = floors.find((fl) => fl.id === id);
        if (f) {
            setEditForm({
                floorNumber: f.floorNumber,
                name: f.name || '',
                mapFileName: f.svgMapUrl || f.svgContent ? 'Existing Map' : '',
                svgContent: f.svgContent || null,
                mapFileObject: null,
                svgMapUrl: f.svgMapUrl || null,
            });
        } else {
            setEditForm({ floorNumber: '', name: '', mapFileName: '', svgContent: null, mapFileObject: null });
        }
        setEditError('');
        setEditSuccess('');
    };

    const handleFileSelect = async (e, formSetter) => {
        const file = e.target.files?.[0];
        if (!file) return;
        const isSvg = file.type.includes('svg') || file.name.toLowerCase().endsWith('.svg');
        if (!isSvg) { setAddError('Please upload a valid SVG file'); return; }
        const content = await readSvgFile(file);
        formSetter(prev => ({ ...prev, mapFileName: file.name, mapFileObject: file, svgContent: content }));
        setAddError('');
        setEditError('');
    };

    // ── Add Floor Submit ──────────────────────────────────────────────────
    const handleAddSubmit = async (e) => {
        e.preventDefault();
        setAddError('');
        setAddSuccess('');
        if (!addForm.floorNumber) { setAddError('Floor number is required'); return; }
        setAddLoading(true);
        try {
            await addFloor(building.id, {
                floorNumber: addForm.floorNumber,
                name: addForm.name,
                mapFileObject: addForm.mapFileObject,
                svgContent: addForm.svgContent,
            });
            setAddSuccess('Floor added successfully!');
            setAddForm({ floorNumber: '', name: '', mapFile: null, mapFileName: '', svgContent: null, mapFileObject: null });
            await loadFloors();
        } catch (err) {
            setAddError(err.message || 'Failed to add floor');
        } finally {
            setAddLoading(false);
        }
    };

    // ── Edit Floor Submit ─────────────────────────────────────────────────
    const handleEditSubmit = async (e) => {
        e.preventDefault();
        setEditError('');
        setEditSuccess('');
        if (!editFloorId) { setEditError('Please select a floor to edit'); return; }
        if (!editForm.floorNumber) { setEditError('Floor number is required'); return; }
        setEditLoading(true);
        try {
            await addFloor(building.id, {
                floorNumber: editForm.floorNumber,
                name: editForm.name,
                mapFileObject: editForm.mapFileObject,
                svgContent: editForm.svgContent,
                svgMapUrl: editForm.svgMapUrl || null,
            });
            setEditSuccess('Floor updated successfully!');
            await loadFloors();
        } catch (err) {
            setEditError(err.message || 'Failed to update floor');
        } finally {
            setEditLoading(false);
        }
    };

    if (!building) return null;

    const lat = building.latitude?.toFixed(5) ?? '—';
    const lng = building.longitude?.toFixed(5) ?? '—';
    const totalFloors = building.totalFloors ?? floors.length ?? 0;

    return (
        <div className="bd-page">

            {/* ── Page Header ─────────────────────────────────────── */}
            <div className="bd-topbar">
                <div className="bd-topbar__left">
                    <button className="bd-back-btn" onClick={onBack}>
                        <FaArrowLeft size={14} />
                    </button>
                    <h1 className="bd-topbar__title">{building.name}</h1>
                </div>
                <div className="bd-topbar__search">
                    <span className="bd-topbar__search-icon">🔍</span>
                    <input className="bd-topbar__search-input" placeholder="Search..." />
                </div>
                <div className="bd-topbar__avatar">AR</div>
            </div>

            {/* ── Building Info Card (dark) ────────────────────────── */}
            <div className="bd-infocard">
                <div className="bd-infocard__thumb">
                    {building.imageUrl
                        ? <img src={building.imageUrl} alt={building.name} />
                        : <div className="bd-infocard__thumb-placeholder"><FaLayerGroup size={20} color="#9aa4af" /></div>}
                </div>
                <div className="bd-infocard__text">
                    <div className="bd-infocard__floors">
                        <FaLayerGroup size={13} color="#9aa4af" />
                        {totalFloors} Floor{totalFloors !== 1 ? 's' : ''}
                    </div>
                    <div className="bd-infocard__coords">
                        <FaMapMarkerAlt size={11} color="#9aa4af" />
                        {lat}, {lng}
                    </div>
                </div>
                <button className="bd-infocard__edit-btn" onClick={onEdit}>Edit</button>
            </div>

            {error && (
                <div className="bd-error">{error}</div>
            )}

            {/* ── Two-Column Layout ────────────────────────────────── */}
            <div className="bd-layout">

                {/* LEFT: Floor selector + SVG Preview */}
                <div className="bd-left">
                    {/* Floor Selector Dropdown */}
                    <div className="bd-floor-select-wrap">
                        <select
                            className="bd-floor-select"
                            onChange={handleSelectFloor}
                            defaultValue=""
                        >
                            <option value="" disabled>Select Floor Map</option>
                            {floors.map((f) => (
                                <option key={f.id} value={f.id}>
                                    Floor {f.floorNumber}{f.name ? ` — ${f.name}` : ''}
                                </option>
                            ))}
                        </select>
                        <span className="bd-floor-select__caret">▾</span>
                    </div>

                    {/* SVG Map Viewer */}
                    {loading ? (
                        <div className="bd-svgviewer bd-svgviewer--empty">
                            <span style={{ color: '#9aa4af' }}>Loading floors...</span>
                        </div>
                    ) : (
                        <SvgViewer floor={previewFloor} />
                    )}
                </div>

                {/* RIGHT: Add / Edit Tabs */}
                <div className="bd-right">
                    {/* Tab Switcher */}
                    <div className="bd-tabs">
                        <button
                            className={`bd-tab ${activeTab === 'add' ? 'bd-tab--active' : ''}`}
                            onClick={() => { setActiveTab('add'); setAddError(''); setAddSuccess(''); }}
                        >
                            Add Floor Map
                        </button>
                        <button
                            className={`bd-tab ${activeTab === 'edit' ? 'bd-tab--active' : ''}`}
                            onClick={() => { setActiveTab('edit'); setEditError(''); setEditSuccess(''); }}
                        >
                            Edit Floor Map
                        </button>
                    </div>

                    {/* ── ADD FLOOR FORM ── */}
                    {activeTab === 'add' && (
                        <form className="bd-form" onSubmit={handleAddSubmit}>
                            {addError && <div className="bd-form__error">{addError}</div>}
                            {addSuccess && <div className="bd-form__success">{addSuccess}</div>}

                            <div className="bd-form__row">
                                <div className="bd-form__group bd-form__group--sm">
                                    <label className="bd-form__label">Floor Number</label>
                                    <input
                                        className="bd-form__input"
                                        type="number"
                                        placeholder="e.g. 1"
                                        value={addForm.floorNumber}
                                        onChange={e => setAddForm(p => ({ ...p, floorNumber: e.target.value }))}
                                    />
                                </div>
                                <div className="bd-form__group bd-form__group--lg">
                                    <label className="bd-form__label">Floor Name</label>
                                    <input
                                        className="bd-form__input"
                                        type="text"
                                        placeholder="e.g. Ground Floor"
                                        value={addForm.name}
                                        onChange={e => setAddForm(p => ({ ...p, name: e.target.value }))}
                                    />
                                </div>
                            </div>

                            <div className="bd-form__group">
                                <label className="bd-form__label">Floor Number</label>
                                <input
                                    className="bd-form__input"
                                    type="number"
                                    placeholder="e.g. 1"
                                    value={addForm.floorNumber}
                                    onChange={e => setAddForm(p => ({ ...p, floorNumber: e.target.value }))}
                                />
                            </div>

                            <div className="bd-form__group">
                                <label className="bd-form__label">Floor Map (SVG only)</label>
                                <UploadZone
                                    fileName={addForm.mapFileName}
                                    onChange={e => handleFileSelect(e, setAddForm)}
                                />
                            </div>

                            <button
                                type="submit"
                                className="bd-form__submit"
                                disabled={addLoading}
                            >
                                {addLoading ? 'Saving...' : 'Add Map'}
                            </button>
                        </form>
                    )}

                    {/* ── EDIT FLOOR FORM ── */}
                    {activeTab === 'edit' && (
                        <form className="bd-form" onSubmit={handleEditSubmit}>
                            {editError && <div className="bd-form__error">{editError}</div>}
                            {editSuccess && <div className="bd-form__success">{editSuccess}</div>}

                            <div className="bd-form__group">
                                <label className="bd-form__label">Select Floor</label>
                                <input
                                    className="bd-form__input"
                                    list="floors-list"
                                    placeholder="e.g. 1"
                                    value={editFloorId}
                                    onChange={(e) => {
                                        const id = e.target.value;
                                        setEditFloorId(id);
                                        const f = floors.find(fl => fl.id === id);
                                        if (f) {
                                            setEditForm({
                                                floorNumber: f.floorNumber,
                                                name: f.name || '',
                                                mapFileName: (f.svgMapUrl || f.svgContent) ? 'Existing Map' : '',
                                                svgContent: f.svgContent || null,
                                                mapFileObject: null,
                                                svgMapUrl: f.svgMapUrl || null,
                                            });
                                        }
                                    }}
                                />
                                <datalist id="floors-list">
                                    {floors.map(f => (
                                        <option key={f.id} value={f.id}>Floor {f.floorNumber}{f.name ? ` — ${f.name}` : ''}</option>
                                    ))}
                                </datalist>
                            </div>

                            <div className="bd-form__row">
                                <div className="bd-form__group bd-form__group--sm">
                                    <label className="bd-form__label">Floor Number</label>
                                    <input
                                        className="bd-form__input"
                                        type="number"
                                        placeholder="e.g. 1"
                                        value={editForm.floorNumber}
                                        onChange={e => setEditForm(p => ({ ...p, floorNumber: e.target.value }))}
                                    />
                                </div>
                                <div className="bd-form__group bd-form__group--lg">
                                    <label className="bd-form__label">Floor Name</label>
                                    <input
                                        className="bd-form__input"
                                        type="text"
                                        placeholder="e.g. Ground Floor"
                                        value={editForm.name}
                                        onChange={e => setEditForm(p => ({ ...p, name: e.target.value }))}
                                    />
                                </div>
                            </div>

                            <div className="bd-form__group">
                                <label className="bd-form__label">Floor Number</label>
                                <input
                                    className="bd-form__input"
                                    type="number"
                                    placeholder="e.g. 1"
                                    value={editForm.floorNumber}
                                    onChange={e => setEditForm(p => ({ ...p, floorNumber: e.target.value }))}
                                />
                            </div>

                            <div className="bd-form__group">
                                <label className="bd-form__label">Floor Map (SVG only)</label>
                                <UploadZone
                                    fileName={editForm.mapFileName}
                                    onChange={e => handleFileSelect(e, setEditForm)}
                                />
                            </div>

                            <button
                                type="submit"
                                className="bd-form__submit"
                                disabled={editLoading}
                            >
                                {editLoading ? 'Updating...' : 'Update Details'}
                            </button>
                        </form>
                    )}
                </div>
            </div>
        </div>
    );
};

export default BuildingDetails;
