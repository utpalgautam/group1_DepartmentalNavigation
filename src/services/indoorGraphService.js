// src/services/indoorGraphService.js
import { db } from './firebaseConfig';
import {
    doc,
    setDoc,
    updateDoc,
    serverTimestamp,
    getDoc
} from 'firebase/firestore';

const INDOOR_GRAPHS_COLLECTION = 'IndoorGraphs';

/**
 * Get the indoor graph for a specific building and floor
 * @param {string} buildingId 
 * @param {number} floorNo 
 */
export const getIndoorGraph = async (buildingId, floorNo) => {
    try {
        const docId = `${buildingId}_floor_${floorNo}`;
        const docRef = doc(db, INDOOR_GRAPHS_COLLECTION, docId);
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
            return { id: docSnap.id, ...docSnap.data() };
        } else {
            return { buildingId, floorNo, nodes: [], edges: [] };
        }
    } catch (error) {
        console.error("Error fetching indoor graph:", error);
        throw error;
    }
};

/**
 * Save or update the entire indoor graph for a floor
 * @param {string} buildingId 
 * @param {number} floorNo 
 * @param {Object} graphData - { nodes, edges }
 */
export const saveIndoorGraph = async (buildingId, floorNo, graphData) => {
    try {
        const docId = `${buildingId}_floor_${floorNo}`;
        const docRef = doc(db, INDOOR_GRAPHS_COLLECTION, docId);
        
        await setDoc(docRef, {
            buildingId,
            floorNo: Number(floorNo),
            ...graphData,
            updatedAt: serverTimestamp()
        }, { merge: true });

        return { id: docId, ...graphData };
    } catch (error) {
        console.error("Error saving indoor graph:", error);
        throw error;
    }
};

/**
 * Helper to update only nodes or edges
 */
export const updateGraphPartial = async (buildingId, floorNo, part) => {
    try {
        const docId = `${buildingId}_floor_${floorNo}`;
        const docRef = doc(db, INDOOR_GRAPHS_COLLECTION, docId);
        
        await updateDoc(docRef, {
            ...part,
            updatedAt: serverTimestamp()
        });
    } catch (error) {
        // If doc doesn't exist, we might need to create it using setDoc first
        console.error("Error updating graph partial:", error);
        throw error;
    }
};

/**
 * Create a new node with SVG native coordinates
 * @param {string} label
 * @param {number} x - SVG coordinate x
 * @param {number} y - SVG coordinate y
 * @param {string} type - "room" | "hallway" | "stairs" | "entrance"
 * @returns {Object} Node object
 */
export const createNode = (label, x, y, type = 'room') => {
    const id = `node_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    return {
        id,
        label,
        x: parseFloat(x.toFixed(2)),
        y: parseFloat(y.toFixed(2)),
        type
    };
};

/**
 * Create a new edge
 * @param {string} fromNodeId
 * @param {string} toNodeId
 * @param {number} weight - optional edge weight (default 1)
 * @returns {Object} Edge object
 */
export const createEdge = (fromNodeId, toNodeId, weight = 1) => {
    const id = `edge_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    return {
        id,
        from: fromNodeId,
        to: toNodeId,
        weight
    };
};
