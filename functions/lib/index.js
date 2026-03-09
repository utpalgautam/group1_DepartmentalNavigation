import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import cors from 'cors';
import { buildingFromFirestore, buildingToFirestore } from './models';
admin.initializeApp();
const db = admin.firestore();
const corsHandler = cors({ origin: true });
// Get all buildings
export const getBuildings = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
        try {
            const snapshot = await db.collection('buildings').get();
            const buildings = snapshot.docs.map(doc => ({
                id: doc.id,
                ...buildingFromFirestore(doc.data(), doc.id),
            }));
            res.status(200).json({ success: true, data: buildings });
        }
        catch (error) {
            console.error('Error fetching buildings:', error);
            res.status(500).json({ success: false, error: String(error) });
        }
    });
});
// Get single building by ID
export const getBuilding = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
        try {
            const { id } = req.query;
            if (!id || typeof id !== 'string') {
                return res.status(400).json({ success: false, error: 'Building ID is required' });
            }
            const doc = await db.collection('buildings').doc(id).get();
            if (!doc.exists) {
                return res.status(404).json({ success: false, error: 'Building not found' });
            }
            const building = {
                id: doc.id,
                ...buildingFromFirestore(doc.data(), doc.id),
            };
            res.status(200).json({ success: true, data: building });
        }
        catch (error) {
            console.error('Error fetching building:', error);
            res.status(500).json({ success: false, error: String(error) });
        }
    });
});
// Add new building
export const addBuilding = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).json({ success: false, error: 'Method not allowed' });
        }
        try {
            const { name, department, latitude, longitude, totalFloors, entryPoints } = req.body;
            // Validation
            if (!name || typeof name !== 'string' || name.trim() === '') {
                return res.status(400).json({ success: false, error: 'Building name is required' });
            }
            if (!department || typeof department !== 'string' || department.trim() === '') {
                return res.status(400).json({ success: false, error: 'Department is required' });
            }
            if (latitude === undefined || longitude === undefined) {
                return res.status(400).json({ success: false, error: 'Latitude and longitude are required' });
            }
            if (!totalFloors || Number(totalFloors) < 1) {
                return res.status(400).json({ success: false, error: 'Number of floors must be at least 1' });
            }
            // Validate entry points
            if (!Array.isArray(entryPoints) || entryPoints.length === 0) {
                return res.status(400).json({ success: false, error: 'At least one entry point is required' });
            }
            const validatedEntryPoints = entryPoints.map((ep, idx) => {
                if (!ep.label || typeof ep.label !== 'string') {
                    throw new Error(`Entry point ${idx + 1}: Label is required`);
                }
                if (ep.latitude === undefined || ep.longitude === undefined) {
                    throw new Error(`Entry point ${idx + 1}: Latitude and longitude are required`);
                }
                return {
                    id: `ep-${Date.now()}-${idx}`,
                    label: ep.label,
                    latitude: Number(ep.latitude),
                    longitude: Number(ep.longitude),
                };
            });
            const buildingData = {
                name: name.trim(),
                latitude: Number(latitude),
                longitude: Number(longitude),
                entryPoints: validatedEntryPoints,
                totalFloors: Number(totalFloors),
            };
            const docRef = await db.collection('buildings').add(buildingToFirestore(buildingData));
            res.status(201).json({
                success: true,
                data: {
                    id: docRef.id,
                    ...buildingData,
                },
            });
        }
        catch (error) {
            console.error('Error adding building:', error);
            res.status(500).json({ success: false, error: String(error) });
        }
    });
});
// Update building
export const updateBuilding = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
        if (req.method !== 'PUT' && req.method !== 'POST') {
            return res.status(405).json({ success: false, error: 'Method not allowed' });
        }
        try {
            const { id } = req.query;
            if (!id || typeof id !== 'string') {
                return res.status(400).json({ success: false, error: 'Building ID is required' });
            }
            const { name, department, latitude, longitude, totalFloors, entryPoints } = req.body;
            // Check if building exists
            const docRef = db.collection('buildings').doc(id);
            const docSnapshot = await docRef.get();
            if (!docSnapshot.exists) {
                return res.status(404).json({ success: false, error: 'Building not found' });
            }
            const existingData = docSnapshot.data();
            const updateData = {};
            if (name !== undefined) {
                if (typeof name !== 'string' || name.trim() === '') {
                    return res.status(400).json({ success: false, error: 'Building name must be a non-empty string' });
                }
                updateData.name = name.trim();
            }
            if (department !== undefined) {
                if (typeof department !== 'string' || department.trim() === '') {
                    return res.status(400).json({ success: false, error: 'Department must be a non-empty string' });
                }
                updateData.department = department.trim();
            }
            if (latitude !== undefined)
                updateData.latitude = Number(latitude);
            if (longitude !== undefined)
                updateData.longitude = Number(longitude);
            if (totalFloors !== undefined)
                updateData.totalFloors = Number(totalFloors);
            if (entryPoints !== undefined) {
                if (!Array.isArray(entryPoints) || entryPoints.length === 0) {
                    return res.status(400).json({ success: false, error: 'At least one entry point is required' });
                }
                const validatedEntryPoints = entryPoints.map((ep, idx) => {
                    if (!ep.label || typeof ep.label !== 'string') {
                        throw new Error(`Entry point ${idx + 1}: Label is required`);
                    }
                    if (ep.latitude === undefined || ep.longitude === undefined) {
                        throw new Error(`Entry point ${idx + 1}: Latitude and longitude are required`);
                    }
                    return {
                        id: ep.id || `ep-${Date.now()}-${idx}`,
                        label: ep.label,
                        latitude: Number(ep.latitude),
                        longitude: Number(ep.longitude),
                    };
                });
                updateData.entryPoints = validatedEntryPoints;
            }
            await docRef.update(updateData);
            const updatedDoc = await docRef.get();
            res.status(200).json({
                success: true,
                data: {
                    id: updatedDoc.id,
                    ...buildingFromFirestore(updatedDoc.data(), updatedDoc.id),
                },
            });
        }
        catch (error) {
            console.error('Error updating building:', error);
            res.status(500).json({ success: false, error: String(error) });
        }
    });
});
// Delete building
export const deleteBuilding = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
        if (req.method !== 'DELETE') {
            return res.status(405).json({ success: false, error: 'Method not allowed' });
        }
        try {
            const { id } = req.query;
            if (!id || typeof id !== 'string') {
                return res.status(400).json({ success: false, error: 'Building ID is required' });
            }
            const docRef = db.collection('buildings').doc(id);
            const docSnapshot = await docRef.get();
            if (!docSnapshot.exists) {
                return res.status(404).json({ success: false, error: 'Building not found' });
            }
            await docRef.delete();
            res.status(200).json({ success: true, message: 'Building deleted successfully' });
        }
        catch (error) {
            console.error('Error deleting building:', error);
            res.status(500).json({ success: false, error: String(error) });
        }
    });
});
