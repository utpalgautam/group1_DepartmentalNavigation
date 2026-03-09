// TypeScript models for Firestore documents
// Each model includes `fromFirestore` and `toFirestore` helpers
export function buildingFromFirestore(data, id) {
    return {
        id,
        name: data?.name ?? '',
        latitude: Number(data?.latitude ?? 0),
        longitude: Number(data?.longitude ?? 0),
        entryPoints: Array.isArray(data?.entryPoints) ? data.entryPoints.map((e) => ({
            id: e.id ?? '', label: e.label ?? '', latitude: Number(e.latitude ?? 0), longitude: Number(e.longitude ?? 0)
        })) : [],
        totalFloors: data?.totalFloors ?? 1,
    };
}
export function buildingToFirestore(b) {
    return {
        name: b.name,
        latitude: b.latitude,
        longitude: b.longitude,
        entryPoints: (b.entryPoints ?? []).map(ep => ({ id: ep.id, label: ep.label, latitude: ep.latitude, longitude: ep.longitude })),
        totalFloors: b.totalFloors ?? 1,
    };
}
