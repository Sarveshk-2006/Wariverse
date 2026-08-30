const fs = require('fs');
let content = fs.readFileSync('lib/api.ts', 'utf-8');

const fallbackMock = `
  '/feedback': [
    { id: 'f1', user: 'Varkari Ramesh', message: 'Water shortage near Solapur highway.', priority: 'HIGH', status: 'PENDING', timestamp: new Date().toISOString() },
    { id: 'f2', user: 'Mauli Tukaram', message: 'Medical camp needed at next stop.', priority: 'MEDIUM', status: 'RESOLVED', timestamp: new Date(Date.now() - 3600000).toISOString() },
    { id: 'f3', user: 'Anonymous', message: 'Road is too crowded.', priority: 'LOW', status: 'PENDING', timestamp: new Date(Date.now() - 7200000).toISOString() },
  ],
`;

content = content.replace("  '/cleaner/log': [", fallbackMock + "\n  '/cleaner/log': [");

const firebaseCode = `
      if (endpoint === '/feedback') {
        const snap = await getDocs(collection(fbDb, 'feedback'));
        if (!snap.empty) {
          return snap.docs.map(d => ({ id: d.id, ...d.data() }));
        }
      }
      if (endpoint.startsWith('/feedback/') && options.method === 'PATCH') {
        const id = endpoint.split('/')[2];
        const body = JSON.parse(options.body);
        await updateDoc(doc(fbDb, 'feedback', id), body);
        return { success: true };
      }
`;

content = content.replace("if (endpoint === '/shelters') {", firebaseCode + "\n      if (endpoint === '/shelters') {");

fs.writeFileSync('lib/api.ts', content);
console.log("Updated api.ts");
