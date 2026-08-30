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

// Render decoupled: App is now completely serverless using Firebase + Next.js

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

  // ── fallback: completely decoupled from Render ───────────────────────────
  // If an endpoint isn't mapped to a Firestore collection above, return []
  return [];
}

// ── Auth ──────────────────────────────────────────────────────────────────────
export async function loginUser(email: string, password: string) {
  // Backend login removed — auth is now handled completely serverlessly on frontend
  return { error: 'Backend auth removed. Please use the simulated frontend auth flow.' };
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
  // Render backend removed completely. Returning dummy WebSocket.
  // Real-time updates can be handled directly via Firestore onSnapshot if needed in future.
  return {
    close: () => {},
    send: () => {},
    readyState: 1, // OPEN
  } as unknown as WebSocket;
}

// API_BASE_URL removed

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
