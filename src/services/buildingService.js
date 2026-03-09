// src/services/buildingService.js
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

const COLLECTION = 'buildings';

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
 * Generates a sequential ID (e.g., B1, B2) for buildings.
 */
async function generateNextBuildingId() {
  const querySnapshot = await getDocs(collection(db, COLLECTION));
  let maxId = 0;
  querySnapshot.forEach(docSnap => {
    const idStr = docSnap.id;
    if (idStr.startsWith('B')) {
      const num = parseInt(idStr.substring(1), 10);
      if (!isNaN(num) && num > maxId) {
        maxId = num;
      }
    }
  });
  return `B${maxId + 1}`;
}

export async function fetchAllBuildings() {
  try {
    const querySnapshot = await getDocs(collection(db, COLLECTION));
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  } catch (error) {
    console.error('Error fetching buildings:', error);
    throw error;
  }
}

export async function fetchBuilding(buildingId) {
  try {
    const docRef = doc(db, COLLECTION, buildingId);
    const docSnapshot = await getDoc(docRef);
    if (docSnapshot.exists()) {
      return { id: docSnapshot.id, ...docSnapshot.data() };
    }
    return null;
  } catch (error) {
    console.error('Error fetching building:', error);
    throw error;
  }
}

export async function addBuilding(buildingData, customId = null) {
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

    const buildingId = customId || await generateNextBuildingId();

    // 1. Upload Main Building Photo (if any)
    let imageUrl = buildingData.imageUrl || null;
    if (buildingData.imageFile) {
      imageUrl = await fileToBase64(buildingData.imageFile);
    }

    // 2. Upload Entry Point Photos
    const processedEntryPoints = await Promise.all(
      buildingData.entryPoints.map(async (ep, idx) => {
        let epImageUrl = ep.imageUrl || null;
        if (ep.imageFile) {
          epImageUrl = await fileToBase64(ep.imageFile);
        }
        return {
          id: ep.id,
          label: ep.label,
          latitude: Number(ep.latitude),
          longitude: Number(ep.longitude),
          imageUrl: epImageUrl,
        };
      })
    );

    const dataToAdd = {
      name: buildingData.name,
      department: buildingData.department || '',
      latitude: Number(buildingData.latitude),
      longitude: Number(buildingData.longitude),
      imageUrl,
      entryPoints: processedEntryPoints,
      totalFloors: Number(buildingData.totalFloors) || 1,
      createdAt: new Date().toISOString(),
    };

    await setDoc(doc(db, COLLECTION, buildingId), dataToAdd);
    return { id: buildingId, ...dataToAdd };
  } catch (error) {
    console.error('Error adding building:', error);
    throw error;
  }
}

export async function updateBuilding(buildingId, buildingData) {
  try {
    const docRef = doc(db, COLLECTION, buildingId);

    // Check if building exists
    const docSnapshot = await getDoc(docRef);
    if (!docSnapshot.exists()) {
      throw new Error('Building not found');
    }

    const dataToUpdate = {};

    if (buildingData.name !== undefined) dataToUpdate.name = buildingData.name;
    if (buildingData.department !== undefined) dataToUpdate.department = buildingData.department;
    if (buildingData.latitude !== undefined) dataToUpdate.latitude = Number(buildingData.latitude);
    if (buildingData.longitude !== undefined) dataToUpdate.longitude = Number(buildingData.longitude);
    if (buildingData.totalFloors !== undefined) dataToUpdate.totalFloors = Number(buildingData.totalFloors);

    // Update Main Building Photo
    if (buildingData.imageFile) {
      dataToUpdate.imageUrl = await fileToBase64(buildingData.imageFile);
    } else if (buildingData.imageUrl !== undefined) {
      dataToUpdate.imageUrl = buildingData.imageUrl;
    }

    if (buildingData.entryPoints) {
      dataToUpdate.entryPoints = await Promise.all(
        buildingData.entryPoints.map(async (ep, idx) => {
          let epImageUrl = ep.imageUrl || null;
          if (ep.imageFile) {
            epImageUrl = await fileToBase64(ep.imageFile);
          }
          return {
            id: ep.id,
            label: ep.label,
            latitude: Number(ep.latitude),
            longitude: Number(ep.longitude),
            imageUrl: epImageUrl,
          };
        })
      );
    }

    dataToUpdate.updatedAt = new Date().toISOString();

    await updateDoc(docRef, dataToUpdate);
  } catch (error) {
    console.error('Error updating building:', error);
    throw error;
  }
}

export async function deleteBuilding(buildingId) {
  try {
    const docRef = doc(db, COLLECTION, buildingId);
    await deleteDoc(docRef);
  } catch (error) {
    console.error('Error deleting building:', error);
    throw error;
  }
}
