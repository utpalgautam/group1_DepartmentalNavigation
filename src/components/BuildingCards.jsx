import { FaMapMarkerAlt } from 'react-icons/fa';

const BuildingCards = ({ buildings, onBuildingClick, onDelete, onAddBuilding }) => {
  return (
    <div className="buildings-grid">
      {buildings.map((building) => {
        const lat = building.latitude ?? building.coordinates?.lat ?? building.coordinates?.latitude;
        const lng = building.longitude ?? building.coordinates?.lng ?? building.coordinates?.longitude;
        const coords = (lat != null && lng != null)
          ? `${parseFloat(lat).toFixed(5)}, ${parseFloat(lng).toFixed(5)}`
          : null;
        const floors = building.totalFloors ?? building.floors ?? building.numFloors;

        return (
          <div key={building.id} className="building-card">
            {/* Building Image */}
            <div className="building-card-image">
              {building.imageUrl
                ? <img src={building.imageUrl} alt={building.name} />
                : <div className="building-card-image-placeholder" />}
            </div>

            {/* Card Content */}
            <div className="building-card-body">
              <div className="building-card-name">{building.name}</div>

              <div className="building-card-meta">
                {coords && (
                  <span className="building-card-coords">
                    <FaMapMarkerAlt size={9} />
                    {coords}
                  </span>
                )}
                {floors != null && (
                  <span className="building-card-floors" style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ color: '#9ca3af', position: 'relative', top: '-1px' }}>
                      <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
                      <polyline points="2 12 12 17 22 12"></polyline>
                      <polyline points="2 17 12 22 22 17"></polyline>
                    </svg>
                    {floors} Floor{floors !== 1 ? 's' : ''}
                  </span>
                )}
              </div>

              <div className="building-card-actions">
                <button
                  className="building-btn building-btn-remove"
                  onClick={(e) => { e.stopPropagation(); onDelete(building.id); }}
                >
                  Remove
                </button>
                <button
                  className="building-btn building-btn-view"
                  onClick={(e) => { e.stopPropagation(); onBuildingClick(building); }}
                >
                  View
                </button>
              </div>
            </div>
          </div>
        );
      })}

      {/* Add Building Placeholder */}
      <div className="building-card-add" onClick={onAddBuilding}>
        <div className="building-card-add-icon">+</div>
        <div className="building-card-add-label">Add Building</div>
      </div>
    </div>
  );
};

export default BuildingCards;