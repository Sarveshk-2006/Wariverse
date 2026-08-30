const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

const firebaseConfig = {
  projectId: "wariverse-a8fca",
  apiKey: "AIzaSyCF9SRQF-mIwy1G2PzYGnOLZ7cU1rcScZc"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function run() {
  // We can't list all collections without admin SDK, but we can try 'reports', 'feedback'
  const collectionsToTry = ['reports', 'feedback', 'feedbacks', 'issues', 'sos', 'user_feedback'];
  
  for (const col of collectionsToTry) {
    try {
      const snap = await getDocs(collection(db, col));
      console.log(`Collection ${col}: ${snap.size} documents`);
      if (snap.size > 0) {
        snap.forEach(doc => {
            console.log(doc.id, doc.data());
        });
      }
    } catch(e) {
      console.log(`Failed for ${col}: ${e.message}`);
    }
  }
  process.exit(0);
}
run();
