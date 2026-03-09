// src/services/floorService.js
import { db, storage } from './firebaseConfig';
import {
    collection,
    getDocs,
    getDoc,
    setDoc,
    doc
} from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';

export async function addFloor(buildingId, floorData) {
    console.log('addFloor called with:', { buildingId, floorNumber: floorData.floorNumber });
    try {
        if (!buildingId) throw new Error('Building ID is required');
        if (floorData.floorNumber === undefined || floorData.floorNumber === null) {
            throw new Error('Floor number is required');
        }

        const floorNumber = Number(floorData.floorNumber);
        const floorDocId = `F${floorNumber}`;

        let svgMapUrl = floorData.svgMapUrl || null;
        let svgContent = floorData.svgContent || null;

        // Upload to Storage if mapped file is present
        if (floorData.mapFileObject) {
            const storagePath = `buildings/${buildingId}/floors/map_${floorDocId}.svg`;
            console.log(`Starting upload to: ${storagePath}`);
            console.log('File details:', { name: floorData.mapFileObject.name, size: floorData.mapFileObject.size, type: floorData.mapFileObject.type });

            const uploadWithTimeout = () => {
                return new Promise(async (resolve, reject) => {
                    const timeout = setTimeout(() => {
                        reject(new Error('Upload timed out after 30 seconds. This might be a CORS or configuration issue.'));
                    }, 30000);

                    try {
                        const storageRef = ref(storage, storagePath);
                        const metadata = {
                            contentType: 'image/svg+xml',
                        };

                        console.log('Calling uploadBytes...');
                        const uploadResult = await uploadBytes(storageRef, floorData.mapFileObject, metadata);
                        console.log('uploadBytes finished:', uploadResult.ref.fullPath);

                        const url = await getDownloadURL(storageRef);
                        console.log('getDownloadURL finished:', url);

                        clearTimeout(timeout);
                        resolve(url);
                    } catch (err) {
                        clearTimeout(timeout);
                        reject(err);
                    }
                });
            };

            try {
                svgMapUrl = await uploadWithTimeout();
            } catch (storageError) {
                console.warn('Storage operation failed (likely CORS), relying on Firestore fallback:', storageError);
            }
        }

        console.log('Updating Firestore document in floormap collection...');
        const globalFloorId = `${buildingId}_F${floorNumber}`;
        const floorDocRef = doc(db, 'floormap', globalFloorId);

        const dataToSave = {
            id: globalFloorId,
            buildingId,
            floorNumber,
            svgMapUrl,
            svgContent, // Storing raw SVG text in Firestore document
            name: floorData.name || `Floor ${floorNumber}`,
            description: floorData.description || '',
            updatedAt: new Date().toISOString(),
        };

        const existingDoc = await getDoc(floorDocRef);
        if (!existingDoc.exists()) {
            dataToSave.createdAt = dataToSave.updatedAt;
        }

        await setDoc(floorDocRef, dataToSave, { merge: true });
        console.log('Firestore update complete (floormap collection)');
        return { id: globalFloorId, ...dataToSave };
    } catch (error) {
        console.error('Error in addFloor:', error);
        throw error;
    }
}

export async function deleteFloor(buildingId, floorId, svgMapUrl = null) {
    try {
        const { deleteDoc: firestoreDelete } = await import('firebase/firestore');

        // 1. Delete from top-level 'floormap' collection
        // Ensure floorId is the global one (e.g., B1_F0)
        const globalFloorId = floorId.includes('_') ? floorId : `${buildingId}_${floorId}`;
        const globalFloorRef = doc(db, 'floormap', globalFloorId);
        await firestoreDelete(globalFloorRef);

        // 2. Delete from Storage if URL exists
        if (svgMapUrl && svgMapUrl.includes('firebasestorage.googleapis.com')) {
            try {
                const storageRef = ref(storage, svgMapUrl);
                await deleteObject(storageRef);
                console.log('Storage object deleted successfully');
            } catch (storageErr) {
                console.warn('Failed to delete storage object (it might not exist):', storageErr.message);
            }
        }
    } catch (error) {
        console.error('Error deleting floor:', error);
        throw error;
    }
}

export async function fetchFloors(buildingId) {
    try {
        const { query, where } = await import('firebase/firestore');
        const floorsRef = collection(db, 'floormap');
        const q = query(floorsRef, where('buildingId', '==', buildingId));
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
        }));
    } catch (error) {
        console.error('Error fetching floors from global collection:', error);
        throw error;
    }
}

