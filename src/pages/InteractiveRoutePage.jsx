import { useState, useEffect } from 'react';
import Header from '../components/Header';
import RouteManagement from '../components/RouteManagement';
import { fetchAllBuildings } from '../services/buildingService';
import { fetchFloors } from '../services/floorService';

const InteractiveRoutePage = () => {
    const [buildings, setBuildings] = useState([]);
    const [selectedBuildingId, setSelectedBuildingId] = useState('');
    const [floors, setFloors] = useState([]);
    const [selectedFloorNumber, setSelectedFloorNumber] = useState('');
    const [loading, setLoading] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        const loadBuildings = async () => {
            try {
                const data = await fetchAllBuildings();
                setBuildings(data);
                if (data.length > 0) setSelectedBuildingId(data[0].id);
            } catch (err) {
                console.error("Failed to load buildings", err);
            }
        };
        loadBuildings();
    }, []);

    useEffect(() => {
        if (!selectedBuildingId) return;
        const loadFloors = async () => {
            try {
                setLoading(true);
                const data = await fetchFloors(selectedBuildingId);
                data.sort((a, b) => a.floorNumber - b.floorNumber);
                setFloors(data);
                if (data.length > 0) {
                    setSelectedFloorNumber(data[0].floorNumber.toString());
                } else {
                    setSelectedFloorNumber('');
                }
            } catch (err) {
                console.error("Failed to load floors", err);
            } finally {
                setLoading(false);
            }
        };
        loadFloors();
    }, [selectedBuildingId]);

    return (
        <div className="ir-page-container">
            <Header
                title="Indoor Navigation Management"
                searchTerm={searchTerm}
                onSearchChange={e => setSearchTerm(e.target.value)}
            />

            <div className="ir-controls-row">
                <div className="ir-select-pill">
                    <label>Building</label>
                    <select
                        value={selectedBuildingId}
                        onChange={(e) => setSelectedBuildingId(e.target.value)}
                    >
                        {buildings.map(b => (
                            <option key={b.id} value={b.id}>{b.name}</option>
                        ))}
                    </select>
                </div>
                <div className="ir-select-pill">
                    <label>Floor</label>
                    <select
                        value={selectedFloorNumber}
                        onChange={(e) => setSelectedFloorNumber(e.target.value)}
                    >
                        {floors.map(f => (
                            <option key={f.floorNumber} value={f.floorNumber.toString()}>
                                {f.floorNumber === 0 ? 'Ground Floor' : `Floor ${f.floorNumber}`}
                            </option>
                        ))}
                    </select>
                </div>
            </div>

            <RouteManagement
                buildingId={selectedBuildingId}
                floorNumber={selectedFloorNumber}
            />
        </div>
    );
};

export default InteractiveRoutePage;
