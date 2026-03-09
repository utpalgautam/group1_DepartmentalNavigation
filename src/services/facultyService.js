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
    where
} from 'firebase/firestore';

const FACULTY_COLLECTION = 'faculty';
const LOCATIONS_COLLECTION = 'locations';

/**
 * Helper to convert an image file to a compressed Base64 string for direct Firestore storage.
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

                // Compress as JPEG
                resolve(canvas.toDataURL('image/jpeg', 0.8));
            };
            img.onerror = reject;
        };
        reader.onerror = reject;
    });
};

/**
 * Generates a sequential ID (e.g., F1, F2) for the faculty.
 */
async function generateNextFacultyId() {
    const snapshot = await getDocs(collection(db, FACULTY_COLLECTION));
    let maxId = 0;
    snapshot.forEach(docSnap => {
        const idStr = docSnap.id;
        if (idStr.startsWith('F')) {
            const num = parseInt(idStr.substring(1), 10);
            if (!isNaN(num) && num > maxId) {
                maxId = num;
            }
        }
    });
    return `F${maxId + 1}`;
}

export async function fetchAllFaculty() {
    try {
        const snapshot = await getDocs(collection(db, FACULTY_COLLECTION));
        return snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
    } catch (err) {
        console.error('Error fetching faculty:', err);
        throw err;
    }
}

export async function addFaculty(facultyData) {
    try {
        // 1. Validate required fields
        if (!facultyData.name) throw new Error('Faculty name is required');
        if (!facultyData.building) throw new Error('Building is required for location mapping');

        // 2. We need to create a Location model first, to get a location ID
        const nextFacultyId = await generateNextFacultyId();
        // Use the same ID for location for simplicity, or generate a fresh doc
        // It's cleaner to let location have its own auto ID or match it
        const locationRef = doc(collection(db, LOCATIONS_COLLECTION));

        const locationData = {
            name: facultyData.name, // Exactly matches faculty name
            type: 'faculty', // Based on LocationType.Faculty
            // We parse the building ID if it's there. Usually building is a name, but let's store it.
            description: `Faculty: ${facultyData.role || ''} - Cabin ${facultyData.cabin || ''}`,
            roomNumber: facultyData.cabin || '',
            floor: facultyData.floor ? parseInt(facultyData.floor) || 1 : 1, // Store as number if possible
            buildingId: facultyData.building || '', // Store the building ID (e.g. B1)
            isActive: true,
            tags: ['faculty', facultyData.role, facultyData.name].filter(Boolean)
        };

        await setDoc(locationRef, locationData);

        // 3. Process Profile Picture Base64
        let imageUrl = facultyData.imageUrl || null;
        if (facultyData.imageFile) {
            imageUrl = await fileToBase64(facultyData.imageFile);
        }

        // 4. Create the faculty document
        const finalFacultyData = {
            name: facultyData.name,
            email: facultyData.email || '',
            role: facultyData.role || '',
            cabin: facultyData.cabin || '',
            building: facultyData.building || '', // This is now the building ID
            floor: facultyData.floor || '',
            imageUrl: imageUrl,
            locationId: locationRef.id, // Store the reference to the created location
            createdAt: new Date().toISOString()
        };

        const docRef = doc(db, FACULTY_COLLECTION, nextFacultyId);
        await setDoc(docRef, finalFacultyData);

        return { id: nextFacultyId, ...finalFacultyData };
    } catch (err) {
        console.error('Error adding faculty:', err);
        throw err;
    }
}

export async function updateFaculty(facultyId, facultyData) {
    try {
        const docRef = doc(db, FACULTY_COLLECTION, facultyId);
        const snap = await getDoc(docRef);
        if (!snap.exists()) throw new Error('Faculty not found');

        const existingData = snap.data();

        // Update Faculty
        const dataToUpdate = { ...facultyData, updatedAt: new Date().toISOString() };

        // Handle Base64 Image Compression Update
        if (facultyData.imageFile) {
            dataToUpdate.imageUrl = await fileToBase64(facultyData.imageFile);
        } else if (facultyData.imageUrl !== undefined) {
            dataToUpdate.imageUrl = facultyData.imageUrl;
        }

        // Remove transient file object from payload before saving
        delete dataToUpdate.imageFile;
        delete dataToUpdate.id; // ensure ID is not in data payload
        await updateDoc(docRef, dataToUpdate);

        // If there is an associated location entry, update its details too
        if (existingData.locationId) {
            const locRef = doc(db, LOCATIONS_COLLECTION, existingData.locationId);
            const locSnap = await getDoc(locRef);
            if (locSnap.exists()) {
                const locUpdate = {};
                if (facultyData.name !== undefined) locUpdate.name = facultyData.name; // Keep name synced
                if (facultyData.role !== undefined || facultyData.cabin !== undefined) {
                    locUpdate.description = `Faculty: ${facultyData.role || existingData.role} - Cabin ${facultyData.cabin || existingData.cabin}`;
                }
                if (facultyData.cabin !== undefined) locUpdate.roomNumber = facultyData.cabin;
                if (facultyData.building !== undefined) locUpdate.buildingId = facultyData.building;
                if (facultyData.floor !== undefined) locUpdate.floor = parseInt(facultyData.floor) || 1;

                // Keep tags in sync
                if (facultyData.name !== undefined || facultyData.role !== undefined) {
                    locUpdate.tags = ['faculty', facultyData.role || existingData.role, facultyData.name || existingData.name].filter(Boolean);
                }

                if (Object.keys(locUpdate).length > 0) {
                    await updateDoc(locRef, locUpdate);
                }
            }
        }
    } catch (err) {
        console.error('Error updating faculty:', err);
        throw err;
    }
}

export async function deleteFaculty(facultyId) {
    try {
        const docRef = doc(db, FACULTY_COLLECTION, facultyId);
        const snap = await getDoc(docRef);
        if (snap.exists()) {
            const data = snap.data();
            // Delete associated location if it exists
            if (data.locationId) {
                try {
                    await deleteDoc(doc(db, LOCATIONS_COLLECTION, data.locationId));
                } catch (e) {
                    console.error('Failed to delete associated location for faculty', e);
                }
            }
            await deleteDoc(docRef);
        }
    } catch (err) {
        console.error('Error deleting faculty:', err);
        throw err;
    }
}
