// src/services/buildingService.ts
import { db } from './firebaseConfig';
import {
  collection,
  getDocs,
  getDoc,
  addDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  doc
} from 'firebase/firestore';

export interface EntryPoint {
  id: string;
  label: string;
  latitude: number;
  longitude: number;
}

export interface Building {
  id?: string;
  name: string;
  department?: string;
  latitude: number;
  longitude: number;
  entryPoints?: EntryPoint[];
  totalFloors?: number;
}

const COLLECTION = 'buildings';

export async function fetchAllBuildings(): Promise<Building[]> {
  try {
    const querySnapshot = await getDocs(collection(db, COLLECTION));
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    })) as Building[];
  } catch (error) {
    console.error('Error fetching buildings:', error);
    throw error;
  }
}

export async function fetchBuilding(buildingId: string): Promise<Building | null> {
  try {
    const docRef = doc(db, COLLECTION, buildingId);
    const docSnapshot = await getDoc(docRef);
    if (docSnapshot.exists()) {
      return { id: docSnapshot.id, ...docSnapshot.data() } as Building;
    }
    return null;
  } catch (error) {
    console.error('Error fetching building:', error);
    throw error;
  }
}

export async function addBuilding(buildingData: Building, customId: string | null = null): Promise<Building> {
  try {
    // Validate input
    if (!buildingData.name || typeof buildingData.name !== 'string') {
      throw new Error('Building name is required');
    }
    if (buildingData.latitude === undefined || buildingData.longitude === undefined) {
      throw new Error('Latitude and longitude are required');
    }
    if (!Array.isArray(buildingData.entryPoints) || buildingData.entryPoints.length === 0) {
      throw new Error('At least one entry point is required');
    }

    const dataToAdd = {
      name: buildingData.name,
      department: buildingData.department || '',
      latitude: Number(buildingData.latitude),
      longitude: Number(buildingData.longitude),
      entryPoints: buildingData.entryPoints.map(ep => ({
        id: ep.id,
        label: ep.label,
        latitude: Number(ep.latitude),
        longitude: Number(ep.longitude),
      })),
      totalFloors: Number(buildingData.totalFloors) || 1,
      createdAt: new Date().toISOString(),
    };

    if (customId) {
      await setDoc(doc(db, COLLECTION, customId), dataToAdd);
      return { id: customId, ...dataToAdd } as Building;
    } else {
      const docRef = await addDoc(collection(db, COLLECTION), dataToAdd);
      return { id: docRef.id, ...dataToAdd } as Building;
    }
  } catch (error) {
    console.error('Error adding building:', error);
    throw error;
  }
}

export async function updateBuilding(buildingId: string, buildingData: Partial<Building>): Promise<void> {
  try {
    const docRef = doc(db, COLLECTION, buildingId);

    // Check if building exists
    const docSnapshot = await getDoc(docRef);
    if (!docSnapshot.exists()) {
      throw new Error('Building not found');
    }

    const dataToUpdate: any = {};

    if (buildingData.name !== undefined) dataToUpdate.name = buildingData.name;
    if (buildingData.department !== undefined) dataToUpdate.department = buildingData.department;
    if (buildingData.latitude !== undefined) dataToUpdate.latitude = Number(buildingData.latitude);
    if (buildingData.longitude !== undefined) dataToUpdate.longitude = Number(buildingData.longitude);
    if (buildingData.totalFloors !== undefined) dataToUpdate.totalFloors = Number(buildingData.totalFloors);

    if (buildingData.entryPoints) {
      dataToUpdate.entryPoints = buildingData.entryPoints.map(ep => ({
        id: ep.id,
        label: ep.label,
        latitude: Number(ep.latitude),
        longitude: Number(ep.longitude),
      }));
    }

    dataToUpdate.updatedAt = new Date().toISOString();

    await updateDoc(docRef, dataToUpdate);
  } catch (error) {
    console.error('Error updating building:', error);
    throw error;
  }
}

export async function deleteBuilding(buildingId: string): Promise<void> {
  try {
    const docRef = doc(db, COLLECTION, buildingId);
    await deleteDoc(docRef);
  } catch (error) {
    console.error('Error deleting building:', error);
    throw error;
  }
}
