// Backend TypeScript models for Firestore documents
// Each model includes `fromFirestore` and `toFirestore` helpers

export interface EntryPoint {
  id: string;
  label: string;
  latitude: number;
  longitude: number;
}

export interface BuildingModel {
  id?: string;
  name: string;
  latitude: number;
  longitude: number;
  entryPoints?: EntryPoint[];
  totalFloors?: number;
}

export function buildingFromFirestore(data: any, id?: string): BuildingModel {
  return {
    id,
    name: data?.name ?? '',
    latitude: Number(data?.latitude ?? 0),
    longitude: Number(data?.longitude ?? 0),
    entryPoints: Array.isArray(data?.entryPoints) ? data.entryPoints.map((e: any) => ({
      id: e.id ?? '', label: e.label ?? '', latitude: Number(e.latitude ?? 0), longitude: Number(e.longitude ?? 0)
    })) : [],
    totalFloors: data?.totalFloors ?? 1,
  };
}

export function buildingToFirestore(b: BuildingModel) {
  return {
    name: b.name,
    latitude: b.latitude,
    longitude: b.longitude,
    entryPoints: (b.entryPoints ?? []).map(ep => ({ id: ep.id, label: ep.label, latitude: ep.latitude, longitude: ep.longitude })),
    totalFloors: b.totalFloors ?? 1,
  };
}

// ----- Faculty -----
export interface FacultyModel {
  id?: string;
  name: string;
  designation: string;
  department: string;
  email: string;
  locationId: string;
  photoUrl?: string;
  researchAreas?: string[];
}

export function facultyFromFirestore(data: any, id?: string): FacultyModel {
  return {
    id,
    name: data?.name ?? '',
    designation: data?.designation ?? '',
    department: data?.department ?? '',
    email: data?.email ?? '',
    locationId: data?.locationId ?? '',
    photoUrl: data?.photoUrl,
    researchAreas: Array.isArray(data?.researchAreas) ? data.researchAreas.map(String) : [],
  };
}

export function facultyToFirestore(f: FacultyModel) {
  return {
    name: f.name,
    designation: f.designation,
    department: f.department,
    email: f.email,
    locationId: f.locationId,
    ...(f.photoUrl ? { photoUrl: f.photoUrl } : {}),
    researchAreas: f.researchAreas ?? [],
  };
}

// ----- Floor Model -----
export interface FloorModel {
  buildingId: string;
  floorNumber: number;
  svgMapData?: string | null;
  svgMapUrl?: string | null;
  mapImageUrl?: string | null;
}

export function floorFromFirestore(data: any, buildingId: string, floorNumber: number): FloorModel {
  return {
    buildingId,
    floorNumber,
    svgMapData: data?.svgMapData ?? null,
    svgMapUrl: data?.svgMapUrl ?? null,
    mapImageUrl: data?.mapImageUrl ?? null,
  };
}

export function floorToFirestore(f: FloorModel) {
  return {
    ...(f.svgMapData != null ? { svgMapData: f.svgMapData } : {}),
    ...(f.svgMapUrl != null ? { svgMapUrl: f.svgMapUrl } : {}),
    ...(f.mapImageUrl != null ? { mapImageUrl: f.mapImageUrl } : {}),
  };
}

// ----- Hall -----
export enum HallType { LectureHall = 'lectureHall', SeminarHall = 'seminarHall', Auditorium = 'auditorium', ConferenceRoom = 'conferenceRoom' }

export interface HallModel { id?: string; name: string; type: HallType; locationId: string; capacity: number; contactPerson?: string }

export function hallFromFirestore(data: any, id?: string): HallModel {
  const t = (String(data?.type ?? 'lectureHall')).toLowerCase();
  const type = t === 'seminarhall' ? HallType.SeminarHall : t === 'auditorium' ? HallType.Auditorium : t === 'conferenceroom' ? HallType.ConferenceRoom : HallType.LectureHall;
  return { id, name: data?.name ?? '', type, locationId: data?.locationId ?? '', capacity: Number(data?.capacity ?? 0), contactPerson: data?.contactPerson };
}

export function hallToFirestore(h: HallModel) {
  return { name: h.name, type: String(h.type), locationId: h.locationId, capacity: h.capacity, ...(h.contactPerson ? { contactPerson: h.contactPerson } : {}) };
}

// ----- Lab -----
export interface LabModel { id?: string; name: string; department: string; locationId: string; capacity: number; incharge?: string; inchargeEmail?: string; timing?: { [k: string]: string } }

export function labFromFirestore(data: any, id?: string): LabModel {
  return { id, name: data?.name ?? '', department: data?.department ?? '', locationId: data?.locationId ?? '', capacity: Number(data?.capacity ?? 0), incharge: data?.incharge, inchargeEmail: data?.inchargeEmail, timing: data?.timing ?? {} };
}

export function labToFirestore(l: LabModel) { return { name: l.name, department: l.department, locationId: l.locationId, capacity: l.capacity, ...(l.incharge ? { incharge: l.incharge } : {}), ...(l.inchargeEmail ? { inchargeEmail: l.inchargeEmail } : {}), timing: l.timing ?? {} }; }


// ----- Location -----
export enum LocationType { Building = 'building', Faculty = 'faculty', Lab = 'lab', Hall = 'hall', Department = 'department', Facility = 'facility', Other = 'other' }

export interface LocationModel { id?: string; name: string; type: LocationType; buildingId?: string; floor?: number; roomNumber?: string; description?: string; tags?: string[]; searchCount?: number; isActive?: boolean }

export function locationFromFirestore(data: any, id?: string): LocationModel {
  const t = String(data?.type ?? 'other').toLowerCase();
  const type = t === 'building' ? LocationType.Building : t === 'faculty' ? LocationType.Faculty : t === 'lab' ? LocationType.Lab : t === 'hall' ? LocationType.Hall : t === 'department' ? LocationType.Department : t === 'facility' ? LocationType.Facility : LocationType.Other;
  return { id, name: data?.name ?? '', type, buildingId: data?.buildingId, floor: data?.floor ?? undefined, roomNumber: data?.roomNumber, description: data?.description, tags: Array.isArray(data?.tags) ? data.tags.map(String) : [], searchCount: Number(data?.searchCount ?? 0), isActive: data?.isActive ?? true };
}

export function locationToFirestore(l: LocationModel) { return { name: l.name, type: String(l.type), ...(l.buildingId ? { buildingId: l.buildingId } : {}), ...(l.floor != null ? { floor: l.floor } : {}), ...(l.roomNumber ? { roomNumber: l.roomNumber } : {}), ...(l.description ? { description: l.description } : {}), tags: l.tags ?? [], searchCount: l.searchCount ?? 0, isActive: l.isActive ?? true }; }

// ----- Route -----
export interface RoutePoint { x: number; y: number }
export interface RouteModel { id?: string; fromLocation: string; toLocation: string; distanceMeters?: number; points: RoutePoint[] }

export function routeFromFirestore(data: any, id?: string): RouteModel { return { id, fromLocation: data?.fromLocation ?? '', toLocation: data?.toLocation ?? '', distanceMeters: Number(data?.distanceMeters ?? 0), points: Array.isArray(data?.points) ? data.points.map((p: any) => ({ x: Number(p.x ?? 0), y: Number(p.y ?? 0) })) : [] }; }

export function routeToFirestore(r: RouteModel) { return { fromLocation: r.fromLocation, toLocation: r.toLocation, distanceMeters: r.distanceMeters ?? 0, points: r.points ?? [] }; }

// ----- User -----
export enum UserType { Student = 'student', Faculty = 'faculty', Staff = 'staff', Guest = 'guest' }

export interface UserModel { uid?: string; email: string; name: string; branch?: string; year?: string; userType: UserType; createdAt?: any; lastLogin?: any; profileImageUrl?: string; savedLocations?: string[]; recentSearches?: string[]; preferences?: { [k: string]: any } }

export function userFromFirestore(data: any, uid?: string): UserModel { return { uid, email: data?.email ?? '', name: data?.name ?? '', branch: data?.branch, year: data?.year, userType: (String(data?.userType ?? 'guest') as UserType), createdAt: data?.createdAt, lastLogin: data?.lastLogin, profileImageUrl: data?.profileImageUrl, savedLocations: Array.isArray(data?.savedLocations) ? data.savedLocations.map(String) : [], recentSearches: Array.isArray(data?.recentSearches) ? data.recentSearches.map(String) : [], preferences: data?.preferences ?? {} }; }

export function userToFirestore(u: UserModel) { return { email: u.email, name: u.name, branch: u.branch ?? null, year: u.year ?? null, userType: String(u.userType), createdAt: u.createdAt ?? null, lastLogin: u.lastLogin ?? null, profileImageUrl: u.profileImageUrl ?? null, savedLocations: u.savedLocations ?? [], recentSearches: u.recentSearches ?? [], preferences: u.preferences ?? {} }; }
