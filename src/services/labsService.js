import { db } from './firebaseConfig';
import {
    collection,
    getDocs,
    getDoc,
    doc,
    setDoc,
    updateDoc,
    deleteDoc
} from 'firebase/firestore';

const LABS_COLLECTION = 'labs';
const LOCATIONS_COLLECTION = 'locations';

/**
 * Helper to convert a map file to a compressed Base64 string for direct Firestore storage.
 * Scaled down to max 800px wide/tall to avoid exceeding Firestore's 1MB document limit.
 */
const fileToBase64 = (file) => {
    return new Promise((resolve, reject) => {
        if (!file) return resolve(null);
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = (e) => {
            const img = new Image();
            img.src = e.target.result;
            img.onload = () => {
                const canvas = document.createElement('canvas');
                const MAX_DIMENSION = 800;
                let { width, height } = img;

                if (width > height) {
                    if (width > MAX_DIMENSION) {
                        height *= MAX_DIMENSION / width;
                        width = MAX_DIMENSION;
                    }
                } else {
                    if (height > MAX_DIMENSION) {
                        width *= MAX_DIMENSION / height;
                        height = MAX_DIMENSION;
                    }
                }
                canvas.width = width;
                canvas.height = height;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0, width, height);

                resolve(canvas.toDataURL('image/jpeg', 0.8));
            };
            img.onerror = reject;
        };
        reader.onerror = reject;
    });
};

/**
 * Generates a sequential ID (e.g., L1, L2) for labs.
 */
async function generateNextId() {
    const snapshot = await getDocs(collection(db, LABS_COLLECTION));
    let maxId = 0;
    snapshot.forEach(docSnap => {
        const idStr = docSnap.id;
        if (idStr.startsWith('L')) {
            const num = parseInt(idStr.substring(1), 10);
            if (!isNaN(num) && num > maxId) {
                maxId = num;
            }
        }
    });
    return `L${maxId + 1}`;
}

export async function fetchAllLabs() {
    try {
        const snapshot = await getDocs(collection(db, LABS_COLLECTION));
        return snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
            category: 'LAB'
        }));
    } catch (err) {
        console.error('Error fetching labs:', err);
        throw err;
    }
}

export async function addLab(itemData) {
    try {
        if (!itemData.name) throw new Error('Name is required');
        if (!itemData.building) throw new Error('Building is required');

        const nextId = await generateNextId();
        const locationRef = doc(collection(db, LOCATIONS_COLLECTION));

        // Create Location Model
        const locationData = {
            name: itemData.name,
            type: 'lab',
            buildingId: itemData.building,
            floor: parseInt(itemData.floor) || 0,
            description: `Lab: ${itemData.name} - ${itemData.status}`,
            isActive: itemData.status === 'ACTIVE',
            tags: ['lab', itemData.name, itemData.building, itemData.department].filter(Boolean)
        };

        await setDoc(locationRef, locationData);

        // Process Map Base64
        let mapUrl = itemData.mapUrl || null;
        if (itemData.mapFile) {
            mapUrl = await fileToBase64(itemData.mapFile);
        }

        // Create Lab Model
        const finalItemData = {
            name: itemData.name,
            department: itemData.department || '',
            locationId: locationRef.id,
            capacity: parseInt(itemData.capacity) || 0,
            incharge: itemData.incharge || null,
            inchargeEmail: itemData.inchargeEmail || null,
            timing: itemData.timing || {},
            building: itemData.building, // Building ID (e.g. B1)
            floor: itemData.floor,
            status: itemData.status,
            mapUrl: mapUrl,
            createdAt: new Date().toISOString()
        };

        const docRef = doc(db, LABS_COLLECTION, nextId);
        await setDoc(docRef, finalItemData);

        return { id: nextId, ...finalItemData };
    } catch (err) {
        console.error('Error adding lab:', err);
        throw err;
    }
}

export async function updateLab(id, itemData) {
    try {
        const docRef = doc(db, LABS_COLLECTION, id);
        const snap = await getDoc(docRef);
        if (!snap.exists()) throw new Error('Lab not found');

        const existingData = snap.data();
        const dataToUpdate = { ...itemData, updatedAt: new Date().toISOString() };

        // Handle Base64 Image Update
        if (itemData.mapFile) {
            dataToUpdate.mapUrl = await fileToBase64(itemData.mapFile);
        } else if (itemData.mapUrl !== undefined) {
            dataToUpdate.mapUrl = itemData.mapUrl;
        }

        delete dataToUpdate.mapFile;
        delete dataToUpdate.id;
        delete dataToUpdate.category;

        await updateDoc(docRef, dataToUpdate);

        // Sync with Location
        if (existingData.locationId) {
            const locRef = doc(db, LOCATIONS_COLLECTION, existingData.locationId);
            const locSnap = await getDoc(locRef);
            if (locSnap.exists()) {
                const locUpdate = {};
                if (itemData.name !== undefined) locUpdate.name = itemData.name;
                if (itemData.building !== undefined) locUpdate.buildingId = itemData.building;
                if (itemData.floor !== undefined) locUpdate.floor = parseInt(itemData.floor) || 0;
                if (itemData.status !== undefined) {
                    locUpdate.isActive = itemData.status === 'ACTIVE';
                    locUpdate.description = `Lab: ${itemData.name || existingData.name} - ${itemData.status}`;
                }

                if (itemData.name !== undefined || itemData.building !== undefined || itemData.department !== undefined) {
                    locUpdate.tags = ['lab', itemData.name || existingData.name, itemData.building || existingData.building, itemData.department || existingData.department].filter(Boolean);
                }

                if (Object.keys(locUpdate).length > 0) {
                    await updateDoc(locRef, locUpdate);
                }
            }
        }
    } catch (err) {
        console.error('Error updating lab:', err);
        throw err;
    }
}

export async function deleteLab(id) {
    try {
        const docRef = doc(db, LABS_COLLECTION, id);
        const snap = await getDoc(docRef);
        if (snap.exists()) {
            const data = snap.data();
            if (data.locationId) {
                await deleteDoc(doc(db, LOCATIONS_COLLECTION, data.locationId));
            }
            await deleteDoc(docRef);
        }
    } catch (err) {
        console.error('Error deleting lab:', err);
        throw err;
    }
}
