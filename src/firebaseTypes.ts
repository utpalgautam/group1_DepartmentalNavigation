// TypeScript interfaces mirroring the Dart models for Firestore documents

export interface FloorModel {
  buildingId: string
  floorNumber: number
  svgMapData?: string
  svgMapUrl?: string
  mapImageUrl?: string
}

export interface EntryPoint { id: string; label: string; latitude: number; longitude: number }

export interface BuildingModel {
  id?: string
  name: string
  latitude: number
  longitude: number
  entryPoints?: EntryPoint[]
  totalFloors?: number
}

export interface FacultyModel {
  id?: string
  name: string
  designation: string
  department: string
  email: string
  locationId: string
  photoUrl?: string
  researchAreas?: string[]
}

export type HallType = 'lectureHall' | 'seminarHall' | 'auditorium' | 'conferenceRoom'

export interface HallModel { id?: string; name: string; type: HallType; locationId: string; capacity: number; contactPerson?: string }

export interface LabModel { id?: string; name: string; department: string; locationId: string; capacity: number; incharge?: string; inchargeEmail?: string; timing?: { [k: string]: string } }

export type LocationType = 'building' | 'faculty' | 'lab' | 'hall' | 'department' | 'facility' | 'other'

export interface LocationModel { id?: string; name: string; type: LocationType; buildingId?: string; floor?: number; roomNumber?: string; description?: string; tags?: string[]; searchCount?: number; isActive?: boolean }

export interface RoutePoint { x: number; y: number }
export interface RouteModel { id?: string; fromLocation: string; toLocation: string; distanceMeters?: number; points: RoutePoint[] }

export type UserType = 'student' | 'faculty' | 'staff' | 'guest'
export interface UserModel { uid?: string; email: string; name: string; branch?: string; year?: string; userType: UserType; createdAt?: any; lastLogin?: any; profileImageUrl?: string; savedLocations?: string[]; recentSearches?: string[]; preferences?: { [k: string]: any } }
