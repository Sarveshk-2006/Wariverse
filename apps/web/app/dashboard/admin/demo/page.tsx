'use client';
import { useState } from 'react';
import { getFirestoreDb } from '@/lib/api';
import { collection, addDoc, getDocs, updateDoc, doc } from 'firebase/firestore';
import Sidebar from '@/components/Sidebar';
import { useLanguage } from '@/context/LanguageContext';

const DEMO_EVENTS = [
  {
    id: 'SOS_EVENT', icon: '🆘', title: 'Trigger SOS Event', color: '#EF4444',
    desc: 'Creates a medical SOS incident. Admin gets notified. Volunteer assigned.',
    steps: ['SOS created in Firestore', 'Nearest volunteer found', 'Admin WebSocket notified', 'SOS appears in live feed'],
  },
  {
    id: 'NETWORK_FAILURE', icon: '📡', title: 'Network Failure', color: '#F59E0B',
    desc: 'Simulates network outage. Offline mode activates. Relay simulation runs.',
    steps: ['Network failure logged', 'App enters offline mode', 'SOS queued locally', 'Relay simulation shows path'],
  },
  {
    id: 'CROWD_SURGE', icon: '🔴', title: 'Crowd Surge', color: '#EF4444',
    desc: 'Increases crowd density across all zones to RED/ORANGE level.',
    steps: ['All zones updated to higher density', 'RED zones appear on map', 'AI prediction updates', 'Route warnings issued'],
  },
  {
    id: 'FOOD_SHORTAGE', icon: '🍛', title: 'Food Shortage', color: '#F97316',
    desc: 'Marks food centres as unavailable. AI recommends additional resources.',
    steps: ['Food centres closed', 'AI detects shortage', 'Resource prediction updates', 'Admin alert triggered'],
  },
  {
    id: 'WATER_SHORTAGE', icon: '💧', title: 'Water Shortage', color: '#3B82F6',
    desc: 'Marks water points as empty. Risk levels update.',
    steps: ['Water points marked EMPTY', 'Water risk level: HIGH', 'Recommendation to refill', 'Map updates'],
  },
  {
    id: 'HEAVY_RAIN', icon: '⛈️', title: 'Heavy Rain Alert', color: '#6366F1',
    desc: 'Triggers weather alert. All Varkaris notified. Route warnings issued.',
    steps: ['Weather alert created', 'Broadcast to all users', 'Route warnings activated', 'Shelter recommendations'],
  },
  {
    id: 'LOST_PERSON', icon: '👤', title: 'Lost Person Case', color: '#EC4899',
    desc: 'Creates a missing person case with QR code.',
    steps: ['Lost person case created in Firestore', 'QR code generated', 'Alert broadcast', 'Volunteers notified'],
  },
  {
    id: 'RESET', icon: '🔄', title: 'Reset Demo Data', color: '#22C55E',
    desc: 'Resets all demo data back to baseline state.',
    steps: ['Crowd zones normalized', 'Food centres reopened', 'Water points refilled', 'Demo ready again'],
  },
];

// ── Firestore-based event handlers ────────────────────────────────────────────
async function handleEvent(eventId: string): Promise<string> {
  const db = getFirestoreDb();
  if (!db) throw new Error('Firebase not ready');

  const now = new Date().toISOString();

  switch (eventId) {
    case 'SOS_EVENT': {
      await addDoc(collection(db, 'sos_alerts'), {
        category: 'MEDICAL',
        status: 'CREATED',
        description: '[DEMO] Medical emergency triggered by control panel',
        latitude: 17.6741 + (Math.random() - 0.5) * 0.05,
        longitude: 75.3279 + (Math.random() - 0.5) * 0.05,
        created_at: now,
        demo: true,
      });
      return 'SOS alert created in Firestore';
    }

    case 'NETWORK_FAILURE': {
      await addDoc(collection(db, 'reports'), {
        type: 'NETWORK_FAILURE',
        title: '[DEMO] Network Failure Simulated',
        status: 'OPEN',
        priority: 'HIGH',
        description: 'Mesh relay offline — fallback mode active',
        created_at: now,
        demo: true,
      });
      return 'Network failure logged in reports';
    }

    case 'CROWD_SURGE': {
      await addDoc(collection(db, 'crowd_data'), {
        zone: 'Pandharpur Main Gate',
        density: 'RED',
        count: 15000,
        timestamp: now,
        demo: true,
      });
      return 'Crowd surge data written to Firestore';
    }

    case 'FOOD_SHORTAGE': {
      const snap = await getDocs(collection(db, 'food_centers'));
      let updated = 0;
      for (const d of snap.docs.slice(0, 5)) {
        await updateDoc(doc(db, 'food_centers', d.id), { status: 'CLOSED', demo_closed: true });
        updated++;
      }
      return `${updated} food centres marked CLOSED`;
    }

    case 'WATER_SHORTAGE': {
      const snap = await getDocs(collection(db, 'water_points'));
      let updated = 0;
      for (const d of snap.docs.slice(0, 5)) {
        await updateDoc(doc(db, 'water_points', d.id), { status: 'EMPTY', demo_closed: true });
        updated++;
      }
      return `${updated} water points marked EMPTY`;
    }

    case 'HEAVY_RAIN': {
      await addDoc(collection(db, 'reports'), {
        type: 'WEATHER_ALERT',
        title: '[DEMO] Heavy Rain Alert — All Routes',
        status: 'OPEN',
        priority: 'HIGH',
        description: 'Heavy rain forecast. Seek shelter immediately.',
        created_at: now,
        demo: true,
      });
      return 'Heavy rain alert written to reports';
    }

    case 'LOST_PERSON': {
      await addDoc(collection(db, 'lost_persons'), {
        name: 'Demo Pilgrim',
        age: 65,
        description: '[DEMO] Elderly pilgrim separated near Vitthal Mandir',
        last_seen: 'Pandharpur Main Gate',
        status: 'MISSING',
        created_at: now,
        demo: true,
      });
      return 'Lost person case created in Firestore';
    }

    case 'RESET': {
      // Re-open food centres and water points that were demo-closed
      const foodSnap = await getDocs(collection(db, 'food_centers'));
      for (const d of foodSnap.docs) {
        const data = d.data();
        if (data.demo_closed) {
          await updateDoc(doc(db, 'food_centers', d.id), { status: 'OPEN', demo_closed: false });
        }
      }
      const waterSnap = await getDocs(collection(db, 'water_points'));
      for (const d of waterSnap.docs) {
        const data = d.data();
        if (data.demo_closed) {
          await updateDoc(doc(db, 'water_points', d.id), { status: 'AVAILABLE', demo_closed: false });
        }
      }
      return 'All demo data reset to baseline';
    }

    default:
      throw new Error(`Unknown event: ${eventId}`);
  }
}

// ── Component ─────────────────────────────────────────────────────────────────
export default function DemoControlPanel() {
  const { t } = useLanguage();
  const [results, setResults] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState<Record<string, boolean>>({});
  const [log, setLog] = useState<string[]>([]);

  const triggerEvent = async (eventId: string) => {
    setLoading(prev => ({ ...prev, [eventId]: true }));
    const ts = new Date().toLocaleTimeString();
    try {
      const message = await handleEvent(eventId);
      setResults(prev => ({ ...prev, [eventId]: { message } }));
      setLog(prev => [`[${ts}] ✅ ${eventId}: ${message}`, ...prev.slice(0, 19)]);
    } catch (e: any) {
      setLog(prev => [`[${ts}] ❌ ${eventId}: ${e.message}`, ...prev.slice(0, 19)]);
    } finally {
      setLoading(prev => ({ ...prev, [eventId]: false }));
    }
  };

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 900 }}>{t('demoControl') || 'Demo Control Panel'}</h1>
            <p style={{ fontSize: '0.75rem', color: '#6B7280' }}>Trigger hackathon demo scenarios — writes live to Firestore</p>
          </div>
          <span className="badge badge-orange">HACKATHON DEMO MODE</span>
        </header>

        <div className="dashboard-content">
          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.5rem' }}>
            <div>
              <h3 style={{ marginBottom: '1rem' }}>⚡ Event Triggers</h3>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem', marginBottom: '1.5rem' }}>
                {DEMO_EVENTS.map(event => (
                  <div key={event.id} className="card card-sm" style={{ border: `2px solid ${event.color}20` }}>
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.75rem', marginBottom: '0.75rem' }}>
                      <div style={{ fontSize: '2rem', flexShrink: 0 }}>{event.icon}</div>
                      <div>
                        <div style={{ fontWeight: 700, fontSize: '0.9rem', color: event.color }}>{event.title}</div>
                        <div style={{ fontSize: '0.75rem', color: '#6B7280', marginTop: '0.125rem' }}>{event.desc}</div>
                      </div>
                    </div>
                    <div style={{ marginBottom: '0.75rem' }}>
                      {event.steps.map((s, i) => (
                        <div key={i} style={{ fontSize: '0.7rem', color: '#6B7280', padding: '1px 0' }}>
                          {i + 1}. {s}
                        </div>
                      ))}
                    </div>
                    <button
                      className="btn btn-sm btn-full"
                      style={{ background: event.color, color: 'white', borderColor: event.color }}
                      onClick={() => triggerEvent(event.id)}
                      disabled={loading[event.id]}
                    >
                      {loading[event.id] ? '⏳ Triggering...' : `▶ ${event.title}`}
                    </button>
                    {results[event.id] && (
                      <div style={{ marginTop: '0.5rem', background: '#F0FDF4', borderRadius: 6, padding: '0.375rem 0.5rem', fontSize: '0.7rem', color: '#15803D' }}>
                        ✅ {results[event.id].message}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Event Log */}
            <div>
              <h3 style={{ marginBottom: '1rem' }}>📟 Event Log</h3>
              <div style={{
                background: '#0F172A', borderRadius: 12, padding: '1rem',
                fontFamily: 'monospace', fontSize: '0.75rem', height: 400, overflowY: 'auto',
              }}>
                {log.length === 0 ? (
                  <div style={{ color: '#374151', textAlign: 'center', marginTop: '3rem' }}>
                    No events triggered yet.<br />Click a trigger button above.
                  </div>
                ) : (
                  log.map((entry, i) => (
                    <div key={i} style={{
                      color: entry.includes('✅') ? '#22C55E' : entry.includes('❌') ? '#EF4444' : '#9CA3AF',
                      padding: '2px 0',
                    }}>{entry}</div>
                  ))
                )}
              </div>

              {/* Quick Links */}
              <div className="card" style={{ marginTop: '1rem' }}>
                <h4 style={{ marginBottom: '0.75rem' }}>🔗 Quick Navigation</h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                  {[
                    { label: '🗺️ Digital Twin Map', path: '/dashboard/admin/digital-twin' },
                    { label: '🆘 Live SOS Feed', path: '/dashboard/admin/sos' },
                    { label: `🤖 ${t('aiPredictions') || 'AI Predictions'}`, path: '/dashboard/admin/predictions' },
                    { label: '📊 Analytics', path: '/dashboard/admin/analytics' },
                    { label: '👤 Missing Persons', path: '/dashboard/admin/lost' },
                  ].map(link => (
                    <a key={link.path} href={link.path} className="btn btn-secondary btn-sm" style={{ justifyContent: 'flex-start' }}>
                      {link.label}
                    </a>
                  ))}
                </div>
              </div>

              <div className="card" style={{ marginTop: '1rem', background: '#0F172A', color: 'white' }}>
                <div style={{ fontSize: '0.7rem', color: '#FB923C', fontWeight: 700, marginBottom: '0.5rem' }}>
                  🔥 LIVE FIREBASE MODE
                </div>
                <p style={{ fontSize: '0.75rem', color: '#9CA3AF', lineHeight: 1.5 }}>
                  Events write directly to Firestore. Changes are visible in real-time across all dashboards.
                </p>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
