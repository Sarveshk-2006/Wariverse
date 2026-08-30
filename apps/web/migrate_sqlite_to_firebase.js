const { initializeApp } = require('firebase/app');
const { getFirestore, collection, doc, setDoc } = require('firebase/firestore');

const firebaseConfig = {
  projectId: "wariverse-a8fca",
  apiKey: "AIzaSyCF9SRQF-mIwy1G2PzYGnOLZ7cU1rcScZc"
};
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Data from SQLite
const sqlite_food = [
    {"id":"fc_01","name":"Vithal Annadan Kendra","latitude":17.6741,"longitude":75.3279,"capacity":1500,"current_count":390,"estimated_queue_minutes":5,"available_now":false,"provider":"Varkari Seva Mandal"},
    {"id":"fc_02","name":"Rukhmini Bhojanalaay","latitude":17.678,"longitude":75.325,"capacity":1092,"current_count":520,"estimated_queue_minutes":8,"available_now":false,"provider":"Shri Trust"},
    {"id":"fc_03","name":"Sant Tukaram Prasad","latitude":17.671,"longitude":75.331,"capacity":749,"current_count":607,"estimated_queue_minutes":15,"available_now":true,"provider":"Pune Sansthan"},
    {"id":"fc_04","name":"Mauli Annadan Trust","latitude":17.6845,"longitude":75.316,"capacity":1216,"current_count":409,"estimated_queue_minutes":10,"available_now":false,"provider":"Alandi Trust"},
    {"id":"fc_05","name":"Warkari Seva Bhojan","latitude":17.675,"longitude":75.328,"capacity":1575,"current_count":758,"estimated_queue_minutes":20,"available_now":true,"provider":"Local NGO"},
    {"id":"fc_06","name":"Panduranga Annadan","latitude":17.68,"longitude":75.32,"capacity":1284,"current_count":223,"estimated_queue_minutes":12,"available_now":true,"provider":"Devasthan"},
    {"id":"fc_07","name":"Dnyaneshwar Prasadalay","latitude":17.672,"longitude":75.322,"capacity":1218,"current_count":530,"estimated_queue_minutes":4,"available_now":true,"provider":"Sanstha"},
    {"id":"fc_08","name":"Namdev Bhojan Griha","latitude":17.679,"longitude":75.329,"capacity":1607,"current_count":791,"estimated_queue_minutes":7,"available_now":true,"provider":"Varkari Seva Mandal"},
    {"id":"fc_09","name":"Sopandev Annadan","latitude":17.682,"longitude":75.318,"capacity":1938,"current_count":747,"estimated_queue_minutes":2,"available_now":true,"provider":"Shri Trust"},
    {"id":"fc_10","name":"Changdev Seva Kendra","latitude":17.673,"longitude":75.33,"capacity":672,"current_count":250,"estimated_queue_minutes":9,"available_now":true,"provider":"Pune Sansthan"},
    {"id":"fc_11","name":"Muktabai Bhojan Trust","latitude":17.677,"longitude":75.326,"capacity":434,"current_count":268,"estimated_queue_minutes":14,"available_now":true,"provider":"Alandi Trust"},
    {"id":"fc_12","name":"Janabai Annadan Sewa","latitude":17.676,"longitude":75.327,"capacity":1133,"current_count":704,"estimated_queue_minutes":6,"available_now":true,"provider":"Local NGO"},
    {"id":"fc_13","name":"Eknath Maharaj Prasad","latitude":17.681,"longitude":75.321,"capacity":1147,"current_count":737,"estimated_queue_minutes":18,"available_now":true,"provider":"Devasthan"},
    {"id":"fc_14","name":"Tukaram Maharaj Annadan","latitude":17.683,"longitude":75.319,"capacity":1801,"current_count":911,"estimated_queue_minutes":3,"available_now":true,"provider":"Sanstha"},
    {"id":"fc_15","name":"Bahina Bai Seva","latitude":17.674,"longitude":75.332,"capacity":770,"current_count":416,"estimated_queue_minutes":11,"available_now":true,"provider":"Varkari Seva Mandal"}
];

async function run() {
  for (const fc of sqlite_food) {
    await setDoc(doc(db, 'food_centers', fc.id), fc);
  }
  console.log('Seeded food_centers to Firebase!');
  process.exit(0);
}
run();
