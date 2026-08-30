const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');
const app = initializeApp({ projectId: "wariverse-a8fca", apiKey: "AIzaSyCF9SRQF-mIwy1G2PzYGnOLZ7cU1rcScZc" });
const db = getFirestore(app);
async function run() {
  const collections = ['water_points', 'shelters'];
  const names = new Set();
  for (const col of collections) {
    const snap = await getDocs(collection(db, col));
    snap.forEach(doc => {
      const data = doc.data();
      if (data.name) names.add(data.name);
    });
  }
  const arr = Array.from(names);
  console.log("// --- NEW FIREBASE NAMES ---");
  for (const name of arr) {
    console.log(`    "${name}": "${name}",`);
  }
  process.exit(0);
}
run();
