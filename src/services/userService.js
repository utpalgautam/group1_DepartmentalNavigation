import { db } from './firebaseConfig';
import {
    collection,
    getDocs,
    doc,
    setDoc,
    updateDoc,
    getDoc,
    addDoc,
    deleteDoc,
    serverTimestamp
} from 'firebase/firestore';

const USERS_COLLECTION = 'users';

/**
 * Fetches all users from Firestore.
 * If the collection doesn't exist or is empty, it returns an empty array.
 */
export const fetchAllUsers = async () => {
    try {
        const querySnapshot = await getDocs(collection(db, USERS_COLLECTION));
        return querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
    } catch (error) {
        console.error("Error fetching users: ", error);
        throw error;
    }
};

/**
 * Updates a user's status (active/inactive).
 * @param {string} userId - The ID of the user document.
 * @param {string} newStatus - The new status to set ('active' or 'inactive').
 */
export const updateUserStatus = async (userId, newStatus) => {
    try {
        const userRef = doc(db, USERS_COLLECTION, userId);
        await updateDoc(userRef, {
            status: newStatus,
            updatedAt: new Date().toISOString()
        });
    } catch (error) {
        console.error("Error updating user status: ", error);
        throw error;
    }
};

/**
 * Adds a new user to Firestore.
 * @param {Object} userData - User details (name, email, role, etc.)
 */
export const addUser = async (userData) => {
    try {
        const docRef = await addDoc(collection(db, USERS_COLLECTION), {
            ...userData,
            status: 'active', // Default status
            registrationDate: new Date().toISOString(),
            lastLogin: new Date().toISOString()
        });
        return docRef.id;
    } catch (error) {
        console.error("Error adding user: ", error);
        throw error;
    }
};

/**
 * Updates an existing user's details.
 * @param {string} userId - The ID of the user document.
 * @param {Object} userData - Updated user details.
 */
export const updateUser = async (userId, userData) => {
    try {
        const userRef = doc(db, USERS_COLLECTION, userId);
        await updateDoc(userRef, {
            ...userData,
            updatedAt: new Date().toISOString()
        });
    } catch (error) {
        console.error("Error updating user: ", error);
        throw error;
    }
};

/**
 * Deletes a user from Firestore.
 * @param {string} userId - The ID of the user document.
 */
export const deleteUser = async (userId) => {
    try {
        const userRef = doc(db, USERS_COLLECTION, userId);
        await deleteDoc(userRef);
    } catch (error) {
        console.error("Error deleting user: ", error);
        throw error;
    }
};

/**
 * Mocks a password reset request.
 * In a real-world scenario, this would use Firebase Auth's sendPasswordResetEmail.
 * @param {string} email - The user's email address.
 */
export const resetUserPassword = async (email) => {
    // Mocking the behavior for the admin dashboard
    console.log(`Password reset requested for: ${email}`);
    return true;
};
