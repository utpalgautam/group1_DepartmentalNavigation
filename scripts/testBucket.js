const { initializeApp } = require('firebase/app');
const { getStorage, ref, uploadBytes } = require('firebase/storage');

const firebaseConfig = {
    apiKey: "AIzaSyBCc1qPfgaAaLju7RWiiSCyOjjuFu-VrmQ",
    projectId: "dept-nav-app",
    authDomain: "dept-nav-app.firebaseapp.com",
    databaseURL: "https://dept-nav-app.firebaseio.com",
    storageBucket: "dept-nav-app.firebasestorage.app", // Try this first
    messagingSenderId: "816397169014",
    appId: "1:816397169014:web:8024b5c3efd682ee048a57"
};

const app = initializeApp(firebaseConfig);
const storage = getStorage(app);

async function testBucket() {
    console.log('Testing bucket:', firebaseConfig.storageBucket);
    const testRef = ref(storage, 'test.txt');
    const content = new TextEncoder().encode('test');

    try {
        await uploadBytes(testRef, content);
        console.log('SUCCESS with .firebasestorage.app');
    } catch (err) {
        console.log('FAILED with .firebasestorage.app:', err.message);

        console.log('Trying .appspot.com...');
        const altConfig = { ...firebaseConfig, storageBucket: 'dept-nav-app.appspot.com' };
        const altApp = initializeApp(altConfig, 'alt');
        const altStorage = getStorage(altApp);
        const altRef = ref(altStorage, 'test.txt');

        try {
            await uploadBytes(altRef, content);
            console.log('SUCCESS with .appspot.com');
            console.log('ACTION: Update firebaseConfig.js to use .appspot.com');
        } catch (err2) {
            console.log('FAILED with .appspot.com:', err2.message);
        }
    }
}

testBucket();
