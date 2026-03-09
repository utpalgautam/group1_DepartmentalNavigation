// src/services/locationService.js
import { db } from './firebaseConfig';
import {
    collection,
    getDocs,
    query,
    where
} from 'firebase/firestore';

const LOCATIONS_COLLECTION = 'locations';

/**
 * Fetch all locations (halls, labs, faculty rooms) for a specific building and floor
 */
export const fetchLocationsByFloor = async (buildingId, floorNumber) => {
    try {
        const q = query(
            collection(db, LOCATIONS_COLLECTION),
            where('buildingId', '==', buildingId),
            where('floor', '==', Number(floorNumber))
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
    } catch (error) {
        console.error("Error fetching locations for floor: ", error);
        throw error;
    }
};

/**
 * Fetch all locations for a specific building
 */
export const fetchLocationsByBuilding = async (buildingId) => {
    try {
        const q = query(
            collection(db, LOCATIONS_COLLECTION),
            where('buildingId', '==', buildingId)
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
    } catch (error) {
        console.error("Error fetching locations for building: ", error);
        throw error;
    }
};
