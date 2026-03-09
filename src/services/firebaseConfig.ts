// src/services/firebaseConfig.ts
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY || "AIzaSyBCc1qPfgaAaLju7RWiiSCyOjjuFu-VrmQ",
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID || "dept-nav-app",
  authDomain: "dept-nav-app.firebaseapp.com",
  databaseURL: "https://dept-nav-app.firebaseio.com",
  storageBucket: "dept-nav-app.appspot.com",
  messagingSenderId: "816397169014",
  appId: "1:816397169014:web:8024b5c3efd682ee048a57"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const storage = getStorage(app);
