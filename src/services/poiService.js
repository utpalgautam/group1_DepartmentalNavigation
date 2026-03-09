// src/services/poiService.js
import { db } from './firebaseConfig';
import {
    doc,
    updateDoc,
    arrayUnion,
    arrayRemove,
    getDoc
} from 'firebase/firestore';

/**
 * Add a new POI to a specific floor
 * @param {string} buildingId 
 * @param {number} floorNumber 
 * @param {Object} poi - { name, x, y }
 */
export const addPOI = async (buildingId, floorNumber, poi) => {
    try {
        const floorDocId = `${buildingId}_F${floorNumber}`;
        const floorDocRef = doc(db, 'floormap', floorDocId);

        await updateDoc(floorDocRef, {
            pois: arrayUnion({
                name: poi.name,
                x: Number(poi.x),
                y: Number(poi.y),
                createdAt: new Date().toISOString()
            })
        });

        return { success: true };
    } catch (error) {
        console.error("Error adding POI to floor: ", error);
        throw error;
    }
};

/**
 * Delete a POI from a specific floor
 */
export const deletePOI = async (buildingId, floorNumber, poi) => {
    try {
        const floorDocId = `${buildingId}_F${floorNumber}`;
        const floorDocRef = doc(db, 'floormap', floorDocId);

        await updateDoc(floorDocRef, {
            pois: arrayRemove(poi)
        });

        return { success: true };
    } catch (error) {
        console.error("Error deleting POI from floor: ", error);
        throw error;
    }
};

/**
 * Fetch POIs for a specific floor (Helpers for RouteManagement)
 */
export const getPOIsByFloor = async (buildingId, floorNumber) => {
    try {
        const floorDocId = `${buildingId}_F${floorNumber}`;
        const floorDocRef = doc(db, 'floormap', floorDocId);
        const docSnap = await getDoc(floorDocRef);

        if (docSnap.exists()) {
            return docSnap.data().pois || [];
        }
        return [];
    } catch (error) {
        console.error("Error fetching POIs from floor doc: ", error);
        throw error;
    }
};
