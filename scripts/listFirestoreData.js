const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

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

async function list() {
    console.log('Fetching buildings...');
    try {
        const snapshot = await getDocs(collection(db, 'buildings'));
        console.log(`Found ${snapshot.size} buildings:`);
        snapshot.forEach(doc => {
            console.log(`- ID: ${doc.id}, Name: ${doc.data().name}`);
        });
    } catch (err) {
        console.error('Error:', err);
    }
}

list();
