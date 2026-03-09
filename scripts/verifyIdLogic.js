const buildings = [
    { id: 'B1', name: 'Main Building' },
    { id: 'B2', name: 'IT Lab Complex' },
    { id: 'B3', name: 'CSED Building' },
    { id: 'admin_block', name: 'Administrative Block' },
    { id: 'cse_building_1', name: 'CSE Department Building' },
    { id: 'it_complex', name: 'IT Lab Complex' }
];

const generateNextId = () => {
    if (buildings.length === 0) return 'B1';

    const ids = buildings
        .map(b => b.id)
        .filter(id => /^B\d+$/.test(id))
        .map(id => parseInt(id.substring(1)))
        .filter(num => !isNaN(num));

    const maxId = ids.length > 0 ? Math.max(...ids) : 0;
    return `B${maxId + 1}`;
};

console.log('Next generated ID:', generateNextId());
if (generateNextId() === 'B4') {
    console.log('SUCCESS: Generated B4 correctly');
} else {
    console.log('FAILURE: Expected B4');
}
