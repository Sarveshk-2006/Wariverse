const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
const WS_BASE = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000';

const MOCK_DATA: Record<string, any> = {
  '/users/stats': {
    total_users: 1450000,
    varkaris: 1400000,
    volunteers: 12500,
    active_pilgrims: 1400000,
  },
  '/weather': {
    temperature_c: 29.5,
    feels_like_c: 32.0,
    humidity_pct: 65,
    wind_kmh: 12,
    condition: 'Partly Cloudy',
    rain_probability_pct: 20,
    alerts: [
      { id: 'w1', alert_type: 'HEAT_ADVISORY', message: 'Stay hydrated during afternoon walk between 12 PM - 3 PM.' }
    ]
  },
  '/crowd/current': [
    { id: 'cz1', name: 'Vitthal Mandir Complex', crowd_level: 'RED', current_density: 0.92, estimated_count: 45000, latitude: 17.6741, longitude: 75.3279, zone_type: 'TEMPLE' },
    { id: 'cz2', name: 'Main Gate & VIP Entry', crowd_level: 'ORANGE', current_density: 0.78, estimated_count: 28000, latitude: 17.6780, longitude: 75.3250, zone_type: 'GATE' },
    { id: 'cz3', name: 'Chandrabhaga River Ghat', crowd_level: 'YELLOW', current_density: 0.55, estimated_count: 18000, latitude: 17.6710, longitude: 75.3310, zone_type: 'GHAT' },
    { id: 'cz4', name: 'Wakhari Paldhi Ground', crowd_level: 'GREEN', current_density: 0.30, estimated_count: 12000, latitude: 17.6850, longitude: 75.3150, zone_type: 'GROUND' },
    { id: 'cz5', name: 'Tembi Naka Ringan Area', crowd_level: 'GREEN', current_density: 0.25, estimated_count: 8500, latitude: 17.7600, longitude: 75.2700, zone_type: 'RINGAN' },
  ],
  '/crowd/prediction': {
    predictions: [
      { zone_id: 'cz1', zone_name: 'Vitthal Mandir Complex', current_density: 0.92, predicted_density_30min: 0.98, risk_level: 'HIGH', recommendation: 'Redirect incoming Dindis to Wakhari holding area.' },
      { zone_id: 'cz2', zone_name: 'Main Gate & VIP Entry', current_density: 0.78, predicted_density_30min: 0.85, risk_level: 'HIGH', recommendation: 'Open auxiliary queue lines.' },
      { zone_id: 'cz3', zone_name: 'Chandrabhaga River Ghat', current_density: 0.55, predicted_density_30min: 0.60, risk_level: 'MEDIUM', recommendation: 'Monitor bathing ghat safety barriers.' },
      { zone_id: 'cz4', zone_name: 'Wakhari Paldhi Ground', current_density: 0.30, predicted_density_30min: 0.40, risk_level: 'LOW', recommendation: 'Normal operations.' },
    ]
  },
  '/sos': [
    { id: 'sos1', category: 'MEDICAL', description: 'Elderly pilgrim experiencing heat exhaustion near Temple Gate 2', status: 'CREATED', latitude: 17.6745, longitude: 75.3282, created_at: new Date(Date.now() - 300000).toISOString(), blood_group: 'B+', is_offline: false },
    { id: 'sos2', category: 'DEHYDRATION', description: 'Dehydration reported near River Ghat', status: 'ACKNOWLEDGED', latitude: 17.6712, longitude: 75.3315, created_at: new Date(Date.now() - 900000).toISOString(), blood_group: 'O+', is_offline: false },
    { id: 'sos3', category: 'LOST', description: '8-year-old child separated from Dindi #42', status: 'IN_PROGRESS', latitude: 17.6782, longitude: 75.3252, created_at: new Date(Date.now() - 1500000).toISOString(), is_offline: true },
  ],
  '/food': [
    { id: 'f1', name: 'Maharshi Annadan Kendra #1', provider: 'ISCKON Seva Trust', available_now: true, current_count: 14200, capacity: 20000, estimated_queue_minutes: 10, hygiene_rating: 4.9, opening_time: '06:00', closing_time: '23:00', latitude: 17.6735, longitude: 75.3270 },
    { id: 'f2', name: 'Shri Vitthal Mahaprasad Hall', provider: 'Pandharpur Devasthan', available_now: true, current_count: 28500, capacity: 35000, estimated_queue_minutes: 25, hygiene_rating: 4.8, opening_time: '05:00', closing_time: '23:30', latitude: 17.6750, longitude: 75.3285 },
    { id: 'f3', name: 'Wakhari Free Food Seva', provider: 'Varkari Seva Samiti', available_now: true, current_count: 8900, capacity: 15000, estimated_queue_minutes: 5, hygiene_rating: 4.7, opening_time: '07:00', closing_time: '22:00', latitude: 17.6845, longitude: 75.3160 },
  ],
  '/water': [
    { id: 'w1', name: 'Ghat Water Station Alpha', status: 'AVAILABLE', water_type: 'Chilled RO Purified', is_filtered: true, has_cooling: true, latitude: 17.6715, longitude: 75.3305 },
    { id: 'w2', name: 'Temple Ringan Water Point', status: 'LOW', water_type: 'Filtered Drinking Water', is_filtered: true, has_cooling: false, latitude: 17.6748, longitude: 75.3275 },
    { id: 'w3', name: 'Wakhari Tanker #4', status: 'EMPTY', water_type: 'Clean Municipal Water', is_filtered: false, has_cooling: false, latitude: 17.6855, longitude: 75.3145 },
  ],
  '/toilets': [
    { id: 't1', name: 'Mobile Sanitation Complex A', status: 'CLEAN', total_units: 30, gender: 'Both', rating: 4.8, minutes_since_cleaned: 12, qr_code: 'QR-TOILET-A101', latitude: 17.6738, longitude: 75.3265 },
    { id: 't2', name: 'Ghat Sanitation Block B', status: 'NEEDS_CLEANING', total_units: 20, gender: 'Women Only', rating: 4.1, minutes_since_cleaned: 65, qr_code: 'QR-TOILET-B202', latitude: 17.6718, longitude: 75.3312 },
    { id: 't3', name: 'Wakhari Mobile Vans C', status: 'CLEAN', total_units: 40, gender: 'Both', rating: 4.6, minutes_since_cleaned: 25, qr_code: 'QR-TOILET-C303', latitude: 17.6860, longitude: 75.3155 },
  ],
  '/shelters': [
    { id: 's1', name: 'Bhakt Niwas Dharamshala', shelter_type: 'Dharamshala', capacity: 1200, current_occupancy: 980, available_now: true, has_meals: true, has_toilets: true, latitude: 17.6760, longitude: 75.3290 },
    { id: 's2', name: 'Wakhari Night Shelter Camp', shelter_type: 'Temporary Tent Shelter', capacity: 3000, current_occupancy: 1850, available_now: true, has_meals: true, has_toilets: true, latitude: 17.6840, longitude: 75.3170 },
  ],
  '/medical': [
    { id: 'm1', name: 'Central Emergency Camp #1', location_type: '24/7 Mobile ICU & Field Hospital', capacity: 50, available: true, doctors_on_duty: 8, ambulances_assigned: 4, latitude: 17.6742, longitude: 75.3275 },
    { id: 'm2', name: 'River Ghat First Aid Post', location_type: 'First Aid & Hydration Station', capacity: 20, available: true, doctors_on_duty: 3, ambulances_assigned: 2, latitude: 17.6711, longitude: 75.3308 },
  ],
  '/lost-person': [
    { id: 'lp1', name: 'Rukmini Bai Pawar', age: 72, gender: 'female', status: 'MISSING', description: 'Wearing yellow saree, carrying wooden mala. Separated near Mandir Chowk.', emergency_contact: '+91 98220 12345', qr_code: 'QR-LOST-8841', blood_group: 'O+', last_seen_latitude: 17.6741, last_seen_longitude: 75.3279 },
    { id: 'lp2', name: 'Aarav Sachin Shinde', age: 7, gender: 'male', status: 'MISSING', description: 'Wearing blue kurta, red cap. Lost near Wakhari Paldhi ground.', emergency_contact: '+91 94230 67890', qr_code: 'QR-LOST-9912', blood_group: 'B+', last_seen_latitude: 17.6850, last_seen_longitude: 75.3150 },
    { id: 'lp3', name: 'Namdeo Patil', age: 68, gender: 'male', status: 'FOUND', description: 'Reunited at Central Control Room.', emergency_contact: '+91 98900 54321', qr_code: 'QR-LOST-1022', blood_group: 'A+', last_seen_latitude: 17.6750, last_seen_longitude: 75.3280 },
  ],
  '/relay/nodes': [
    { id: 'rn1', name: 'Pandharpur Gateway Tower', is_online: true, is_gateway: true, connected_devices: 342, latitude: 17.6741, longitude: 75.3279 },
    { id: 'rn2', name: 'Ghat Mesh Node Alpha', is_online: true, is_gateway: false, connected_devices: 184, latitude: 17.6710, longitude: 75.3310 },
    { id: 'rn3', name: 'Wakhari Repeater Beta', is_online: true, is_gateway: false, connected_devices: 215, latitude: 17.6850, longitude: 75.3150 },
  ],
  '/community/posts': [
    { id: 'p1', author_name: 'Anand Volunteer', is_verified: true, post_type: 'FOOD_AVAILABLE', message: 'Fresh Mahaprasad (Pithla Bhakri & Khichdi) being served freely at Maharshi Kendra near Gate 2!', distance_m: 150, upvotes: 48, created_at: new Date(Date.now() - 600000).toISOString(), expires_at: new Date(Date.now() + 7200000).toISOString() },
    { id: 'p2', author_name: 'Traffic Police Patrol', is_verified: true, post_type: 'ROUTE_WARNING', message: 'High crowd density at Vitthal Temple Main Entry. Please use the Wakhari ring road bypass.', distance_m: 350, upvotes: 92, created_at: new Date(Date.now() - 1800000).toISOString(), expires_at: new Date(Date.now() + 10800000).toISOString() },
    { id: 'p3', author_name: 'Dr. Deshmukh Medical Camp', is_verified: true, post_type: 'MEDICAL_HELP', message: 'Free Ayurvedic foot care massage and blister treatments available at Camp #1.', distance_m: 200, upvotes: 35, created_at: new Date(Date.now() - 2400000).toISOString(), expires_at: new Date(Date.now() + 14400000).toISOString() },
  ],
  '/notifications': [
    { id: 'n1', title: '⛈️ Heat Advisory', message: 'High temperatures expected between 12 PM - 3 PM. Drink water frequently.', priority: 'HIGH', is_read: false, created_at: new Date(Date.now() - 3600000).toISOString() },
    { id: 'n2', title: '🚦 Route Diversion', message: 'Vitthal Mandir gate 1 restricted to senior citizens only.', priority: 'MEDIUM', is_read: true, created_at: new Date(Date.now() - 7200000).toISOString() },
  ],
  '/admin/analytics': {
    active_varkaris: 1400000,
    active_sos: 3,
    total_sos: 45,
    red_zones: 1,
    total_crowd_zones: 5,
    active_volunteers: 12500,
    food_centres_open: 3,
    water_points_available: 2,
    lost_persons_missing: 2,
    total_pilgrims_estimate: 1450000,
    timestamp: new Date().toISOString(),
  },
  '/ai/recommend-food': {
    explanation: 'AI Recommendation based on current crowd density and queue times:',
    recommendations: [
      { name: 'Maharshi Annadan Kendra #1', distance_m: 150, walk_minutes: 2, estimated_queue_minutes: 10, ai_score: 9.8 },
      { name: 'Wakhari Free Food Seva', distance_m: 450, walk_minutes: 5, estimated_queue_minutes: 5, ai_score: 9.4 },
      { name: 'Shri Vitthal Mahaprasad Hall', distance_m: 300, walk_minutes: 4, estimated_queue_minutes: 25, ai_score: 8.2 },
    ]
  },
  '/resources/prediction': {
    total_pilgrims_estimate: 1450000,
    food: {
      demand_meals: 45000,
      available_capacity: 43000,
      shortage_meals: 2000,
      shortage_risk: 'HIGH',
      recommendation: 'Divert 2000 meals to Wakhari Camp immediately.'
    },
    water: {
      total_points: 120,
      available_points: 105,
      shortage_risk: 'LOW',
      recommendation: 'Water supply is stable.'
    },
    medical: {
      estimated_cases: 450,
      recommendation: 'Deploy 2 additional mobile clinics to Ghat zone.'
    }
  },
  '/ai/recommend-water': {
    explanation: 'Nearest high-quality water stations:',
    recommendations: [
      { name: 'Ghat Water Station Alpha', distance_m: 120, walk_minutes: 2, water_type: 'RO Purified', ai_score: 9.9 },
    ]
  },
  '/food/nearby': [
    { id: 'f1', name: 'Maharshi Annadan Kendra #1', provider: 'ISCKON Seva Trust', available_now: true, current_count: 14200, capacity: 20000, estimated_queue_minutes: 10, hygiene_rating: 4.9, opening_time: '06:00', closing_time: '23:00', distance_m: 150, walk_minutes: 2, meal_types: ['LUNCH', 'DINNER'], latitude: 17.6735, longitude: 75.3270 },
    { id: 'f2', name: 'Shri Vitthal Mahaprasad Hall', provider: 'Pandharpur Devasthan', available_now: true, current_count: 28500, capacity: 35000, estimated_queue_minutes: 25, hygiene_rating: 4.8, opening_time: '05:00', closing_time: '23:30', distance_m: 300, walk_minutes: 4, meal_types: ['BREAKFAST', 'LUNCH', 'DINNER'], latitude: 17.6750, longitude: 75.3285 },
    { id: 'f3', name: 'Wakhari Free Food Seva', provider: 'Varkari Seva Samiti', available_now: true, current_count: 8900, capacity: 15000, estimated_queue_minutes: 5, hygiene_rating: 4.7, opening_time: '07:00', closing_time: '22:00', distance_m: 450, walk_minutes: 5, meal_types: ['BREAKFAST', 'LUNCH'], latitude: 17.6845, longitude: 75.3160 },
  ],

  /* Additional Admin & Stakeholder Feature Endpoints */
  '/users': [
    { id: 'u1', email: 'varkari@wariverse.demo', display_name: 'Santosh Tukaram', role: 'VARKARI', is_verified: true, is_active: true, created_at: new Date(Date.now() - 864000000).toISOString() },
    { id: 'u2', email: 'volunteer@wariverse.demo', display_name: 'Anand Shinde', role: 'VOLUNTEER', is_verified: true, is_active: true, created_at: new Date(Date.now() - 764000000).toISOString() },
    { id: 'u3', email: 'medical@wariverse.demo', display_name: 'Dr. Priya Kulkarni', role: 'MEDICAL_TEAM', is_verified: true, is_active: true, created_at: new Date(Date.now() - 664000000).toISOString() },
    { id: 'u4', email: 'police@wariverse.demo', display_name: 'Inspector Deshmukh', role: 'POLICE', is_verified: true, is_active: true, created_at: new Date(Date.now() - 564000000).toISOString() },
    { id: 'u5', email: 'ngo@wariverse.demo', display_name: 'Seva Trust Coordinator', role: 'NGO', is_verified: true, is_active: true, created_at: new Date(Date.now() - 464000000).toISOString() },
    { id: 'u6', email: 'provider@wariverse.demo', display_name: 'Annadan Kendra Head', role: 'SERVICE_PROVIDER', is_verified: true, is_active: true, created_at: new Date(Date.now() - 364000000).toISOString() },
    { id: 'u7', email: 'cleaner@wariverse.demo', display_name: 'Swachhata Sevak Ramesh', role: 'CLEANER', is_verified: true, is_active: true, created_at: new Date(Date.now() - 264000000).toISOString() },
    { id: 'u8', email: 'admin@wariverse.demo', display_name: 'Vari Control Admin', role: 'ADMIN', is_verified: true, is_active: true, created_at: new Date(Date.now() - 164000000).toISOString() },
  ],
  '/police/routes': [
    { id: 'r1', route_name: 'Alandi - Pune - Pandharpur Palkhi Route', status: 'HEAVY_CROWD', advisory: 'Ringan procession active at Wakhari. Divert heavy vehicles via Bypass.', active_pilgrims: 450000 },
    { id: 'r2', route_name: 'Dehu - Solapur - Pandharpur Route', status: 'CLEAR', advisory: 'Normal traffic movement.', active_pilgrims: 280000 },
  ],
  '/ngo/volunteers': [
    { id: 'v1', name: 'Anand Shinde', phone: '+91 98220 99887', area: 'Ghat Zone A', status: 'AVAILABLE', tasks_completed: 14 },
    { id: 'v2', name: 'Sunita Patil', phone: '+91 94210 33445', area: 'Medical Camp #1', status: 'ASSIGNED', tasks_completed: 8 },
  ],
  '/ngo/resources': [
    { id: 'res1', item_name: 'Drinking Water Pouches', allocated: 50000, remaining: 18500, risk_level: 'LOW' },
    { id: 'res2', item_name: 'First Aid Medical Kits', allocated: 500, remaining: 80, risk_level: 'MEDIUM' },
    { id: 'res3', item_name: 'Emergency Blankets', allocated: 2000, remaining: 1200, risk_level: 'LOW' },
  ],
  '/provider/charging': [
    { id: 'c1', name: 'Solapur Road Charging Hub', total_ports: 24, available_ports: 8, queue_minutes: 5, status: 'AVAILABLE' },
    { id: 'c2', name: 'Temple Gate Mobile Power Bank', total_ports: 50, available_ports: 2, queue_minutes: 20, status: 'BUSY' },
  ],
  '/provider/wellness': [
    { id: 'w1', name: 'Ayurvedic Foot Care Seva #1', services: ['Foot Massage', 'Blister Care', 'Oil Treatment'], status: 'OPEN', waiting_pilgrims: 12 },
    { id: 'w2', name: 'Pilgrim Rest & Stretch Camp', services: ['Yoga & Rest', 'Hydration Salt Solution'], status: 'OPEN', waiting_pilgrims: 4 },
  ],


  '/reports': [
    { id: 'r1', user: 'Varkari Ramesh', message: 'Water shortage near Solapur highway.', priority: 'HIGH', status: 'PENDING', timestamp: new Date().toISOString() },
    { id: 'r2', user: 'Mauli Tukaram', message: 'Medical emergency at camp 4.', priority: 'HIGH', status: 'RESOLVED', timestamp: new Date(Date.now() - 3600000).toISOString() },
    { id: 'r3', user: 'Anonymous', message: 'Road is too crowded, stampede risk.', priority: 'MEDIUM', status: 'PENDING', timestamp: new Date(Date.now() - 7200000).toISOString() },
  ],
  '/feedback': [
    { id: 'f1', user: 'Varkari Santosh', message: 'The new app is very helpful for finding food.', timestamp: new Date().toISOString() },
    { id: 'f2', user: 'Anonymous', message: 'Please add more local Marathi songs in the connect section.', timestamp: new Date(Date.now() - 86400000).toISOString() },
  ],


  '/cleaner/log': [
    { id: 'cl1', toilet_name: 'Mobile Sanitation Complex A', cleaned_by: 'Swachhata Sevak Ramesh', cleaned_at: new Date(Date.now() - 720000).toISOString(), status: 'COMPLETED' },
    { id: 'cl2', toilet_name: 'Ghat Sanitation Block B', cleaned_by: 'Swachhata Staff Team B', cleaned_at: new Date(Date.now() - 3900000).toISOString(), status: 'NEEDS_INSPECTION' },
  ]
};

import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, updateDoc } from 'firebase/firestore';

let fbDb: any = null;
if (typeof window !== 'undefined') {
  try {
    const app = initializeApp({
      projectId: "wariverse-a8fca",
      apiKey: "AIzaSyCF9SRQF-mIwy1G2PzYGnOLZ7cU1rcScZc"
    });
    fbDb = getFirestore(app);
  } catch (e) {}
}

export async function apiCall(
  endpoint: string,
  options: RequestInit = {},
  token?: string | null
): Promise<any> {
  const actualToken = token || getToken();
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
      if (endpoint.startsWith('/reports/') && options.method === 'PATCH') {
        const id = endpoint.split('/')[2];
        const body = JSON.parse(options.body as string);
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
      if (endpoint.startsWith('/feedback/') && options.method === 'PATCH') {
        const id = endpoint.split('/')[2];
        const body = JSON.parse(options.body as string);
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
}

const MOCK_DEMO_USERS: Record<string, { role: string; display_name: string }> = {
  'varkari@wariverse.demo': { role: 'VARKARI', display_name: 'Santosh Tukaram' },
  'volunteer@wariverse.demo': { role: 'VOLUNTEER', display_name: 'Anand Shinde' },
  'medical@wariverse.demo': { role: 'MEDICAL_TEAM', display_name: 'Dr. Priya Kulkarni' },
  'police@wariverse.demo': { role: 'POLICE', display_name: 'Inspector Deshmukh' },
  'ngo@wariverse.demo': { role: 'NGO', display_name: 'Seva Trust Coordinator' },
  'provider@wariverse.demo': { role: 'SERVICE_PROVIDER', display_name: 'Annadan Kendra Head' },
  'cleaner@wariverse.demo': { role: 'CLEANER', display_name: 'Swachhata Sevak Ramesh' },
  'admin@wariverse.demo': { role: 'ADMIN', display_name: 'Vari Control Admin' },
};

export async function loginUser(email: string, password: string) {
  const formData = new URLSearchParams();
  formData.append('username', email);
  formData.append('password', password);

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

export function createWebSocket(clientId: string, onMessage: (data: any) => void, token?: string | null): WebSocket {
  try {
    const actualToken = token || getToken();
    if (!actualToken) return {} as WebSocket;
    const ws = new WebSocket(`${WS_BASE}/ws/${clientId}?token=${encodeURIComponent(actualToken)}`);
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

export const API_BASE_URL = API_BASE;

export function openDirections(latitude: number, longitude: number, label?: string) {
  if (typeof window === 'undefined') return;
  const destination = label ? `${label}, ${latitude},${longitude}` : `${latitude},${longitude}`;
  window.open(`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(destination)}`, '_blank');
}
