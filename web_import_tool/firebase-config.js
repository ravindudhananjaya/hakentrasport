// Firebase Configuration
// IMPORTANT: Replace these values with your actual Firebase project configuration
// You can find these in your Firebase Console > Project Settings > General





const firebaseConfig = {
    apiKey: "AIzaSyAuOFiBz3apNgQv00sgDIDsfsX5lAMP1hY",
    authDomain: "himchndra-shift-attendant.firebaseapp.com",
    projectId: "himchndra-shift-attendant",
    storageBucket: "himchndra-shift-attendant.firebasestorage.app",
    messagingSenderId: "584626508946",
    appId: "1:584626508946:web:01f39b620fe313a252424b"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firestore
const db = firebase.firestore();

console.log('Firebase initialized successfully');
