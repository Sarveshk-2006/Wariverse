const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');
const app = initializeApp({ projectId: "wariverse-a8fca", apiKey: "AIzaSyCF9SRQF-mIwy1G2PzYGnOLZ7cU1rcScZc" });
const db = getFirestore(app);
async function run() {
  const snap = await getDocs(collection(db, 'food_centers'));
  const names = [];
  snap.forEach(doc => { names.push(doc.data().name); });
  console.log(JSON.stringify(names));
  process.exit(0);
}
run();
