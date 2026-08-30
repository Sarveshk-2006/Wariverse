import { initializeApp, getApps } from 'firebase/app';
import {
  getFirestore,
  collection,
  getDocs,
  doc,
  updateDoc,
  addDoc,
  query,
  orderBy,
  limit,
  where,
} from 'firebase/firestore';

const API_BASE = '/api';
const WS_BASE = process.env.NEXT_PUBLIC_WS_URL || 'wss://variverse.onrender.com';

// ── In-memory cache (5-minute TTL) — prevents Firestore quota exhaustion ──────
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes
const _cache: Record<string, { data: any; ts: number }> = {};

function cacheGet(key: string): any | null {
  const entry = _cache[key];
  if (entry && Date.now() - entry.ts < CACHE_TTL_MS) return entry.data;
  return null;
}

function cacheSet(key: string, data: any) {
  _cache[key] = { data, ts: Date.now() };
}

export function invalidateCache(key?: string) {
  if (key) delete _cache[key];
  else Object.keys(_cache).forEach(k => delete _cache[k]);
}

// ── Firebase init ─────────────────────────────────────────────────────────────
let fbDb: any = null;

if (typeof window !== 'undefined') {
  try {
    const app = getApps().length
      ? getApps()[0]
      : initializeApp({
          apiKey: 'AIzaSyAs-_Vdx_EOveIJKHxHblvwptHpljDpeYM',
          authDomain: 'variverse-79b42.firebaseapp.com',
          projectId: 'variverse-79b42',
          storageBucket: 'variverse-79b42.firebasestorage.app',
          messagingSenderId: '1087752438013',
          appId: '1:1087752438013:web:b4f663929ca26507d77e94',
          measurementId: 'G-04E0VSKK3K',
        });
    fbDb = getFirestore(app);
  } catch (e) {
    console.error('Firebase init error:', e);
  }
}

export function getFirestoreDb() {
  return fbDb;
}

// ── Helpers ───────────────────────────────────────────────────────────────────
async function fetchCollection(col: string) {
  const cached = cacheGet(col);
  if (cached) return cached;
  const snap = await getDocs(collection(fbDb, col));
  const data = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  cacheSet(col, data);
  return data;
}

async function patchDoc(col: string, id: string, data: any) {
  await updateDoc(doc(fbDb, col, id), data);
  return { success: true };
}

// ── Main API call (all from Firestore) ────────────────────────────────────────
export async function apiCall(
  endpoint: string,
  options: RequestInit = {},
  token?: string | null
): Promise<any> {
  if (!fbDb) throw new Error('Firebase not initialised');

  const method = (options.method || 'GET').toUpperCase();
  const body = options.body ? JSON.parse(options.body as string) : null;

  // ── food ──────────────────────────────────────────────────────────────────
  if (endpoint === '/food') return fetchCollection('food_centers');
  if (endpoint.startsWith('/food/') && method === 'PATCH')
    return patchDoc('food_centers', endpoint.split('/')[2], body);

  // ── water ─────────────────────────────────────────────────────────────────
  if (endpoint === '/water') return fetchCollection('water_points');
  if (endpoint.startsWith('/water/') && method === 'PATCH')
    return patchDoc('water_points', endpoint.split('/')[2], body);

  // ── shelters ──────────────────────────────────────────────────────────────
  if (endpoint === '/shelters') return fetchCollection('shelters');
  if (endpoint.startsWith('/shelters/') && method === 'PATCH')
    return patchDoc('shelters', endpoint.split('/')[2], body);

  // ── toilets / sanitation ──────────────────────────────────────────────────
  if (endpoint === '/toilets') return fetchCollection('toilets');
  if (endpoint === '/sanitation_reports') return fetchCollection('sanitation_reports');
  if (endpoint.startsWith('/sanitation_reports/') && method === 'PATCH')
    return patchDoc('sanitation_reports', endpoint.split('/')[2], body);

  // ── SOS ───────────────────────────────────────────────────────────────────
  if (endpoint === '/sos') return fetchCollection('sos_alerts');
  if (endpoint.startsWith('/sos/') && method === 'PATCH')
    return patchDoc('sos_alerts', endpoint.split('/')[2], body);

  // ── reports ───────────────────────────────────────────────────────────────
  if (endpoint === '/reports') return fetchCollection('reports');
  if (endpoint.startsWith('/reports/') && method === 'PATCH')
    return patchDoc('reports', endpoint.split('/')[2], body);
  if (endpoint === '/reports' && method === 'POST') {
    const ref = await addDoc(collection(fbDb, 'reports'), { ...body, created_at: new Date().toISOString() });
    return { id: ref.id, ...body };
  }

  // ── feedback ──────────────────────────────────────────────────────────────
  if (endpoint === '/feedback') return fetchCollection('feedback');
  if (endpoint.startsWith('/feedback/') && method === 'PATCH')
    return patchDoc('feedback', endpoint.split('/')[2], body);
  if (endpoint === '/feedback' && method === 'POST') {
    const ref = await addDoc(collection(fbDb, 'feedback'), { ...body, created_at: new Date().toISOString() });
    return { id: ref.id, ...body };
  }

  // ── community / lost & found ──────────────────────────────────────────────
  if (endpoint === '/community/posts') return fetchCollection('community_posts');
  if (endpoint === '/lost-person') return fetchCollection('lost_persons');
  if (endpoint.startsWith('/lost-person/') && method === 'PATCH')
    return patchDoc('lost_persons', endpoint.split('/')[2], body);

  // ── medical ───────────────────────────────────────────────────────────────
  if (endpoint === '/medical') return fetchCollection('medical_camps');

  // ── wellness / provider ───────────────────────────────────────────────────
  if (endpoint === '/provider/wellness') return fetchCollection('wellness_providers');

  // ── relay nodes ───────────────────────────────────────────────────────────
  if (endpoint === '/relay/nodes') return fetchCollection('relay_nodes');

  // ── crowd data ────────────────────────────────────────────────────────────
  if (endpoint === '/crowd/current') return fetchCollection('crowd_data');
  if (endpoint === '/crowd/prediction') return fetchCollection('crowd_predictions');

  // ── users stats (admin) ───────────────────────────────────────────────────
  if (endpoint === '/users/stats') {
    const snap = await getDocs(collection(fbDb, 'users'));
    const total = snap.size;
    return { total, active: Math.round(total * 0.8) };
  }

  // ── users list (admin) ────────────────────────────────────────────────────
  if (endpoint === '/users') return fetchCollection('users');
  if (endpoint.startsWith('/users/') && method === 'PATCH')
    return patchDoc('users', endpoint.split('/')[2], body);

  // ── AI recommendations — proxy to backend ─────────────────────────────────
  if (endpoint.startsWith('/ai/')) {
    const actualToken = token || getToken();
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (actualToken) headers['Authorization'] = `Bearer ${actualToken}`;
    const res = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
    if (res.ok) return res.json();
    return null;
  }

  // ── nearby locations ──────────────────────────────────────────────────────
  if (endpoint.startsWith('/locations/nearby')) {
    const [food, water, toilets, shelters, medical, wellness] = await Promise.all([
      fetchCollection('food_centers'),
      fetchCollection('water_points'),
      fetchCollection('toilets'),
      fetchCollection('shelters'),
      fetchCollection('medical_camps'),
      fetchCollection('wellness_providers'),
    ]);
    return { food, water, toilets, shelters, medical, wellness };
  }

  // ── fallback: proxy to Render backend ────────────────────────────────────
  const actualToken = token || getToken();
<<<<<<< HEAD
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (actualToken) {
    headers['Authorization'] = `Bearer ${actualToken}`;
  }

  // Intercept and use Firebase directly for shared collections
  if (fbDb && typeof window !== 'undefined') {
    try {
      if (endpoint === '/food') {
        const snap = await getDocs(collection(fbDb, 'food_centers'));
        return snap.docs.map(d => ({ id: d.id, ...d.data() }));
      }
      if (endpoint.startsWith('/food/') && options.method === 'PATCH') {
        const id = endpoint.split('/')[2];
        const body = JSON.parse(options.body as string);
        await updateDoc(doc(fbDb, 'food_centers', id), body);
        return { success: true };
      }
      if (endpoint === '/water') {
        const snap = await getDocs(collection(fbDb, 'water_points'));
        return snap.docs.map(d => ({ id: d.id, ...d.data() }));
      }
      
      
      if (endpoint === '/reports') {
        const snap = await getDocs(collection(fbDb, 'reports'));
        if (!snap.empty) {
          return snap.docs.map(d => ({ id: d.id, ...d.data() }));
        }
      }
      if (endpoint.startsWith('/reports/') && options?.method === 'PATCH') {
        const id = endpoint.split('/')[2];
        const body = JSON.parse((options.body as string) || '{}');
        await updateDoc(doc(fbDb, 'reports', id), body);
        return { success: true };
      }

      
      if (endpoint === '/sanitation_reports') {
        const snap = await getDocs(collection(fbDb, 'sanitation_reports'));
        if (!snap.empty) {
          return snap.docs.map(d => ({ id: d.id, ...d.data() }));
        }
      }

      if (endpoint === '/feedback') {
        const snap = await getDocs(collection(fbDb, 'feedback'));
        if (!snap.empty) {
          return snap.docs.map(d => ({ id: d.id, ...d.data() }));
        }
      }
      if (endpoint.startsWith('/feedback/') && options?.method === 'PATCH') {
        const id = endpoint.split('/')[2];
        const body = JSON.parse((options.body as string) || '{}');
        await updateDoc(doc(fbDb, 'feedback', id), body);
        return { success: true };
      }

      if (endpoint === '/shelters') {
        const snap = await getDocs(collection(fbDb, 'shelters'));
        return snap.docs.map(d => ({ id: d.id, ...d.data() }));
      }
    } catch (e) {
      console.warn("Firebase fetch failed, falling back to Python API:", e);
    }
  }


  // Hardcoded interception for reports and feedback if backend doesn't support it yet
  if (endpoint === '/sanitation_reports') return MOCK_DATA['/sanitation_reports'] || [];
  if (endpoint === '/reports') return MOCK_DATA['/reports'];
  if (endpoint.startsWith('/sanitation_reports/') && options.method === 'PATCH') return { success: true };
  if (endpoint.startsWith('/reports/') && options.method === 'PATCH') return { success: true };
  if (endpoint === '/feedback') return MOCK_DATA['/feedback'];

  let backendUnavailable = false;

  try {
    const res = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers,
    });

    if (res.ok) {
      return await res.json();
    }

    const detail = await res.text();
    throw new Error(detail || `Request failed with status ${res.status}`);
  } catch (e) {
    if (e instanceof TypeError) {
      backendUnavailable = true;
    } else {
      throw e;
    }
  }

  // Use static demo data only when the backend cannot be reached.
  if (!backendUnavailable) return [];

  const cleanPath = endpoint.split('?')[0];

  if (MOCK_DATA[cleanPath] !== undefined) {
    return MOCK_DATA[cleanPath];
  }

  if (cleanPath.startsWith('/food')) return MOCK_DATA['/food'];
  if (cleanPath.startsWith('/water')) return MOCK_DATA['/water'];
  if (cleanPath.startsWith('/toilets')) return MOCK_DATA['/toilets'];
  if (cleanPath.startsWith('/shelters')) return MOCK_DATA['/shelters'];
  if (cleanPath.startsWith('/medical')) return MOCK_DATA['/medical'];
  if (cleanPath.startsWith('/wellness')) return MOCK_DATA['/provider/wellness'];
  if (cleanPath.startsWith('/lost-person')) return MOCK_DATA['/lost-person'];
  if (cleanPath.startsWith('/community')) return MOCK_DATA['/community/posts'];
  if (cleanPath.startsWith('/sos')) return MOCK_DATA['/sos'];
  if (cleanPath.startsWith('/crowd/current')) return MOCK_DATA['/crowd/current'];
  if (cleanPath.startsWith('/crowd/prediction')) return MOCK_DATA['/crowd/prediction'];
  if (cleanPath.startsWith('/ai/recommend-food')) return MOCK_DATA['/ai/recommend-food'];
  if (cleanPath.startsWith('/ai/recommend-water')) return MOCK_DATA['/ai/recommend-water'];
  if (cleanPath.startsWith('/relay')) return MOCK_DATA['/relay/nodes'];
  if (cleanPath.startsWith('/locations/nearby')) {
    return {
      food: MOCK_DATA['/food'],
      water: MOCK_DATA['/water'],
      toilets: MOCK_DATA['/toilets'],
      shelters: MOCK_DATA['/shelters'],
      medical: MOCK_DATA['/medical'],
      wellness: MOCK_DATA['/provider/wellness'],
    };
  }

  return [];
=======
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (actualToken) headers['Authorization'] = `Bearer ${actualToken}`;
  const res = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
  if (res.ok) return res.json();
  throw new Error(`Request failed: ${res.status}`);
>>>>>>> 1c8334288bf69b146bb98039356bbae805086cd8
}

// ── Auth ──────────────────────────────────────────────────────────────────────
export async function loginUser(email: string, password: string) {
  const formData = new URLSearchParams();
  formData.append('username', email);
  formData.append('password', password);
<<<<<<< HEAD

  let backendUnavailable = false;

=======
>>>>>>> 1c8334288bf69b146bb98039356bbae805086cd8
  try {
    const res = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formData,
    });
    if (res.ok) return await res.json();
    return { error: 'Invalid credentials' };
  } catch (e) {
    return { error: 'Network error' };
  }
}

export function setAuth(token: string, user: any) {
  if (typeof window !== 'undefined') {
    localStorage.setItem('wv_token', token);
    localStorage.setItem('wv_user', JSON.stringify(user));
  }
}

export function getToken() {
  if (typeof window !== 'undefined') return localStorage.getItem('wv_token');
  return null;
}

export function getUser() {
  if (typeof window !== 'undefined') {
    const u = localStorage.getItem('wv_user');
    return u ? JSON.parse(u) : null;
  }
  return null;
}

export function clearAuth() {
  if (typeof window !== 'undefined') {
    localStorage.removeItem('wv_token');
    localStorage.removeItem('wv_user');
  }
}

export function createWebSocket(
  clientId: string,
  onMessage: (data: any) => void,
  token?: string | null
): WebSocket {
  try {
    const actualToken = token || getToken();
    if (!actualToken) return {} as WebSocket;
    const ws = new WebSocket(
      `${WS_BASE}/ws/${clientId}?token=${encodeURIComponent(actualToken)}`
    );
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        onMessage(data);
      } catch {}
    };
    return ws;
  } catch (e) {
    return {} as WebSocket;
  }
}

export const API_BASE_URL = 'https://variverse.onrender.com';

export function openDirections(latitude: number, longitude: number, label?: string) {
  if (typeof window === 'undefined') return;
  const destination = label
    ? `${label}, ${latitude},${longitude}`
    : `${latitude},${longitude}`;
  window.open(
    `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(destination)}`,
    '_blank'
  );
}
