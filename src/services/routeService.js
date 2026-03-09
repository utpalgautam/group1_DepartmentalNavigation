// src/services/routeService.js
import { db } from './firebaseConfig';
import {
    collection,
    addDoc,
    getDocs,
    query,
    where,
    deleteDoc,
    doc,
    updateDoc,
    serverTimestamp
} from 'firebase/firestore';

const ROUTES_COLLECTION = 'routes';

/**
 * Add a new route
 * @param {Object} routeData - { buildingId, floorNumber, fromLocation, toLocation, distanceMeters, points: [{x, y}] }
 */
export const addRoute = async (routeData) => {
    try {
        const docRef = await addDoc(collection(db, ROUTES_COLLECTION), {
            ...routeData,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
        });
        return { id: docRef.id, ...routeData };
    } catch (error) {
        console.error("Error adding route: ", error);
        throw error;
    }
};

/**
 * Fetch all routes for a specific floor in a building
 */
export const getRoutesByFloor = async (buildingId, floorNumber) => {
    try {
        const q = query(
            collection(db, ROUTES_COLLECTION),
            where('buildingId', '==', buildingId),
            where('floorNumber', '==', Number(floorNumber))
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
    } catch (error) {
        console.error("Error fetching routes: ", error);
        throw error;
    }
};

/**
 * Delete a route
 */
export const deleteRoute = async (routeId) => {
    try {
        await deleteDoc(doc(db, ROUTES_COLLECTION, routeId));
    } catch (error) {
        console.error("Error deleting route: ", error);
        throw error;
    }
};

/**
 * Update an existing route
 */
export const updateRoute = async (routeId, routeData) => {
    try {
        const routeRef = doc(db, ROUTES_COLLECTION, routeId);
        await updateDoc(routeRef, {
            ...routeData,
            updatedAt: serverTimestamp()
        });
        return { id: routeId, ...routeData };
    } catch (error) {
        console.error("Error updating route: ", error);
        throw error;
    }
};
