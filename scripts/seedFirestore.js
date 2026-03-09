// scripts/seedFirestore.js
const { initializeApp } = require('firebase/app');
const { getFirestore, setDoc, doc } = require('firebase/firestore');

const firebaseConfig = {
  apiKey: "AIzaSyBCc1qPfgaAaLju7RWiiSCyOjjuFu-VrmQ",
  projectId: "dept-nav-app",
  authDomain: "dept-nav-app.firebaseapp.com",
  databaseURL: "https://dept-nav-app.firebaseio.com",
  storageBucket: "dept-nav-app.firebasestorage.app",
  messagingSenderId: "816397169014",
  appId: "1:816397169014:web:8024b5c3efd682ee048a57"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function seed() {
  console.log('Seeding Firestore with correct data model for dept-nav-app...');

  try {
    // 1. Buildings
    const buildings = [
      { id: 'cse_building_1', name: 'CSE Department Building', latitude: 12.9716, longitude: 77.5946, totalFloors: 4, entryPoints: [{ id: 'e1', label: 'Main Entrance', latitude: 12.9717, longitude: 77.5947 }] },
      { id: 'it_complex', name: 'IT Lab Complex', latitude: 12.9719, longitude: 77.5948, totalFloors: 3, entryPoints: [{ id: 'e1', label: 'North Entrance', latitude: 12.9720, longitude: 77.5949 }] },
      { id: 'admin_block', name: 'Administrative Block', latitude: 12.9710, longitude: 77.5940, totalFloors: 5, entryPoints: [{ id: 'e1', label: 'Front Desk', latitude: 12.9711, longitude: 77.5941 }] }
    ];

    for (const b of buildings) {
      await setDoc(doc(db, 'buildings', b.id), {
        name: b.name,
        latitude: b.latitude,
        longitude: b.longitude,
        totalFloors: b.totalFloors,
        entryPoints: b.entryPoints,
        createdAt: new Date().toISOString()
      }, { merge: true });
      console.log(`- Seeded building: ${b.name}`);
    }

    // 2. Locations
    const locations = [
      { id: 'loc_faculty_1', name: 'Dr. John Doe Office', type: 'faculty', floor: 1, buildingId: 'cse_building_1', description: 'Faculty: Professor - Cabin 101' },
      { id: 'loc_hall_1', name: 'Seminar Hall A', type: 'hall', floor: 2, buildingId: 'it_complex', description: 'Hall: Seminar Hall A - ACTIVE' },
      { id: 'loc_lab_1', name: 'Graphics Lab', type: 'lab', floor: 1, buildingId: 'cse_building_1', description: 'Lab: Graphics Lab - ACTIVE' }
    ];

    for (const loc of locations) {
      await setDoc(doc(db, 'locations', loc.id), loc, { merge: true });
    }

    // 3. Faculty
    const faculty = [
      {
        id: 'F1',
        name: 'Dr. John Doe',
        role: 'Professor',
        cabin: '101',
        building: 'CSE Department Building',
        floor: '1',
        locationId: 'loc_faculty_1',
        createdAt: new Date().toISOString()
      }
    ];

    for (const f of faculty) {
      const { id, ...data } = f;
      await setDoc(doc(db, 'faculty', id), data, { merge: true });
      console.log(`- Seeded faculty: ${f.name}`);
    }

    // 4. Halls
    const halls = [
      {
        id: 'H1',
        name: 'Seminar Hall A',
        type: 'SEMINAR',
        locationId: 'loc_hall_1',
        capacity: 100,
        building: 'IT Lab Complex',
        floor: '2',
        status: 'ACTIVE',
        createdAt: new Date().toISOString()
      }
    ];

    for (const h of halls) {
      const { id, ...data } = h;
      await setDoc(doc(db, 'halls', id), data, { merge: true });
      console.log(`- Seeded hall: ${h.name}`);
    }

    // 5. Labs
    const labs = [
      {
        id: 'L1',
        name: 'Graphics Lab',
        department: 'CSE',
        locationId: 'loc_lab_1',
        capacity: 40,
        building: 'CSE Department Building',
        floor: '1',
        status: 'ACTIVE',
        createdAt: new Date().toISOString()
      }
    ];

    for (const l of labs) {
      const { id, ...data } = l;
      await setDoc(doc(db, 'labs', id), data, { merge: true });
      console.log(`- Seeded lab: ${l.name}`);
    }

    console.log('Seeding complete successfully.');
  } catch (err) {
    console.error('Seeding failed:', err);
  }
}

seed();
