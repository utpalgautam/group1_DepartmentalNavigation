import { db } from './firebaseConfig';
import {
    collection,
    getDocs,
    getDoc,
    doc,
    setDoc,
    updateDoc,
    deleteDoc,
    query,
    orderBy
} from 'firebase/firestore';

const HALLS_COLLECTION = 'halls';
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
 * Generates a sequential ID (e.g., H1, H2) for halls.
 */
async function generateNextId() {
    const snapshot = await getDocs(collection(db, HALLS_COLLECTION));
    let maxId = 0;
    snapshot.forEach(docSnap => {
        const idStr = docSnap.id;
        if (idStr.startsWith('H')) {
            const num = parseInt(idStr.substring(1), 10);
            if (!isNaN(num) && num > maxId) {
                maxId = num;
            }
        }
    });
    return `H${maxId + 1}`;
}

export async function fetchAllHalls() {
    try {
        const snapshot = await getDocs(collection(db, HALLS_COLLECTION));
        return snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
            category: 'HALL'
        }));
    } catch (err) {
        console.error('Error fetching halls:', err);
        throw err;
    }
}

export async function addHall(itemData) {
    try {
        if (!itemData.name) throw new Error('Name is required');
        if (!itemData.building) throw new Error('Building is required');

        const nextId = await generateNextId();
        const locationRef = doc(collection(db, LOCATIONS_COLLECTION));

        // Create Location Model
        const locationData = {
            name: itemData.name,
            type: 'hall',
            buildingId: itemData.building,
            floor: parseInt(itemData.floor) || 0,
            description: `Hall: ${itemData.name} - ${itemData.status}`,
            isActive: itemData.status === 'ACTIVE',
            tags: ['hall', itemData.name, itemData.building].filter(Boolean)
        };

        await setDoc(locationRef, locationData);

        // Process Map Base64
        let mapUrl = itemData.mapUrl || null;
        if (itemData.mapFile) {
            mapUrl = await fileToBase64(itemData.mapFile);
        }

        // Create Hall Model
        const finalItemData = {
            name: itemData.name,
            type: itemData.type,
            locationId: locationRef.id,
            capacity: parseInt(itemData.capacity) || 0,
            contactPerson: itemData.contactPerson || null,
            building: itemData.building, // Building ID (e.g. B1)
            floor: itemData.floor,
            status: itemData.status,
            mapUrl: mapUrl,
            createdAt: new Date().toISOString()
        };

        const docRef = doc(db, HALLS_COLLECTION, nextId);
        await setDoc(docRef, finalItemData);

        return { id: nextId, ...finalItemData };
    } catch (err) {
        console.error('Error adding hall:', err);
        throw err;
    }
}

export async function updateHall(id, itemData) {
    try {
        const docRef = doc(db, HALLS_COLLECTION, id);
        const snap = await getDoc(docRef);
        if (!snap.exists()) throw new Error('Hall not found');

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
                    locUpdate.description = `Hall: ${itemData.name || existingData.name} - ${itemData.status}`;
                }

                if (itemData.name !== undefined || itemData.building !== undefined) {
                    locUpdate.tags = ['hall', itemData.name || existingData.name, itemData.building || existingData.building].filter(Boolean);
                }

                if (Object.keys(locUpdate).length > 0) {
                    await updateDoc(locRef, locUpdate);
                }
            }
        }
    } catch (err) {
        console.error('Error updating hall:', err);
        throw err;
    }
}

export async function deleteHall(id) {
    try {
        const docRef = doc(db, HALLS_COLLECTION, id);
        const snap = await getDoc(docRef);
        if (snap.exists()) {
            const data = snap.data();
            if (data.locationId) {
                await deleteDoc(doc(db, LOCATIONS_COLLECTION, data.locationId));
            }
            await deleteDoc(docRef);
        }
    } catch (err) {
        console.error('Error deleting hall:', err);
        throw err;
    }
}
