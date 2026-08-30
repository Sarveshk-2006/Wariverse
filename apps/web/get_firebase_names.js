const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

const firebaseConfig = {
  projectId: "wariverse-a8fca",
  apiKey: "AIzaSyCF9SRQF-mIwy1G2PzYGnOLZ7cU1rcScZc"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function run() {
  const collections = ['food_centers', 'water_points', 'shelters'];
  const names = new Set();
  
  for (const col of collections) {
    const snap = await getDocs(collection(db, col));
    snap.forEach(doc => {
      const data = doc.data();
      if (data.name) names.add(data.name);
    });
  }
  
  console.log(JSON.stringify(Array.from(names)));
  process.exit(0);
}
run();
