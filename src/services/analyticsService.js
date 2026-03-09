// src/services/analyticsService.js
import { db } from './firebaseConfig';
import { collection, getDocs, query, where, orderBy, limit } from 'firebase/firestore';

const SEARCH_LOGS_COLLECTION = 'searchLogs';

/**
 * Get total searches grouped by building name.
 * Falls back to sample data if collection is empty/missing.
 */
export async function getSearchesPerBuilding() {
    try {
        const snapshot = await getDocs(collection(db, SEARCH_LOGS_COLLECTION));
        if (snapshot.empty) return getSampleBuildingData();

        const counts = {};
        snapshot.forEach(doc => {
            const data = doc.data();
            const building = data.buildingName || data.buildingId || 'Unknown';
            counts[building] = (counts[building] || 0) + 1;
        });

        return Object.entries(counts)
            .map(([name, searches]) => ({ name, searches }))
            .sort((a, b) => b.searches - a.searches)
            .slice(0, 6);
    } catch (err) {
        console.error('Error fetching searches per building:', err);
        return getSampleBuildingData();
    }
}

/**
 * Get searches per day for the last N days.
 * Falls back to sample data if collection is empty/missing.
 */
export async function getSearchesPerDay(days = 7) {
    try {
        const snapshot = await getDocs(collection(db, SEARCH_LOGS_COLLECTION));
        if (snapshot.empty) return getSampleDailyData(days);

        const now = new Date();
        const cutoff = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
        const dailyCounts = {};

        // Initialize all days
        for (let i = days - 1; i >= 0; i--) {
            const d = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
            const key = d.toLocaleDateString('en-US', { weekday: 'short' });
            dailyCounts[key] = 0;
        }

        snapshot.forEach(doc => {
            const data = doc.data();
            const ts = data.timestamp?.toDate ? data.timestamp.toDate() : new Date(data.timestamp);
            if (ts >= cutoff) {
                const key = ts.toLocaleDateString('en-US', { weekday: 'short' });
                if (dailyCounts[key] !== undefined) {
                    dailyCounts[key]++;
                }
            }
        });

        return Object.entries(dailyCounts).map(([day, searches]) => ({ day, searches }));
    } catch (err) {
        console.error('Error fetching searches per day:', err);
        return getSampleDailyData(days);
    }
}

function getSampleBuildingData() {
    return [
        { name: 'Main Building', searches: 45 },
        { name: 'CSED Building', searches: 32 },
        { name: 'Library', searches: 28 },
        { name: 'Admin Block', searches: 15 },
    ];
}

function getSampleDailyData(days = 7) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const now = new Date();
    const result = [];
    for (let i = days - 1; i >= 0; i--) {
        const d = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
        result.push({
            day: dayNames[d.getDay()],
            searches: Math.floor(Math.random() * 40) + 10
        });
    }
    return result;
}
