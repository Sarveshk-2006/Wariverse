with open('lib/api.ts', 'r') as f:
    content = f.read()

mock_reports = """
  '/reports': [
    { id: 'r1', user: 'Varkari Ramesh', message: 'Water shortage near Solapur highway.', priority: 'HIGH', status: 'PENDING', timestamp: new Date().toISOString() },
    { id: 'r2', user: 'Mauli Tukaram', message: 'Medical emergency at camp 4.', priority: 'HIGH', status: 'RESOLVED', timestamp: new Date(Date.now() - 3600000).toISOString() },
    { id: 'r3', user: 'Anonymous', message: 'Road is too crowded, stampede risk.', priority: 'MEDIUM', status: 'PENDING', timestamp: new Date(Date.now() - 7200000).toISOString() },
  ],
  '/feedback': [
    { id: 'f1', user: 'Varkari Santosh', message: 'The new app is very helpful for finding food.', timestamp: new Date().toISOString() },
    { id: 'f2', user: 'Anonymous', message: 'Please add more local Marathi songs in the connect section.', timestamp: new Date(Date.now() - 86400000).toISOString() },
  ],
"""

content = content.replace("  '/feedback': [", mock_reports + "  '/delete_this': [")
# Now delete the old mock_feedback array which is from `/delete_this` to `],`
import re
content = re.sub(r"  '/delete_this': \[.*?\]\,", "", content, flags=re.DOTALL)


firebase_reports = """
      if (endpoint === '/reports') {
        const snap = await getDocs(collection(fbDb, 'reports'));
        if (!snap.empty) {
          return snap.docs.map(d => ({ id: d.id, ...d.data() }));
        }
      }
      if (endpoint.startsWith('/reports/') && options.method === 'PATCH') {
        const id = endpoint.split('/')[2];
        const body = JSON.parse(options.body);
        await updateDoc(doc(fbDb, 'reports', id), body);
        return { success: true };
      }
"""

content = content.replace("if (endpoint === '/feedback') {", firebase_reports + "\n      if (endpoint === '/feedback') {")
# Note that the previous Firebase feedback PATCH handler is still there, which is fine, even if it's unused, or we can just leave it.

with open('lib/api.ts', 'w') as f:
    f.write(content)
