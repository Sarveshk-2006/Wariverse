'use client';
import { useState } from 'react';
import { apiCall, getToken } from '@/lib/api';
import Sidebar from '@/components/Sidebar';
import { useLanguage } from '@/context/LanguageContext';

const DEMO_EVENTS = [
  {
    id: 'SOS_EVENT', icon: '🆘', title: 'Trigger SOS Event', color: '#EF4444',
    desc: 'Creates a medical SOS incident. Admin gets notified. Volunteer assigned.',
    steps: ['SOS created in database', 'Nearest volunteer found', 'Admin WebSocket notified', 'SOS appears in live feed'],
  },
  {
    id: 'NETWORK_FAILURE', icon: '📡', title: 'Network Failure', color: '#F59E0B',
    desc: 'Simulates network outage. Offline mode activates. Relay simulation runs.',
    steps: ['Network failure broadcast', 'App enters offline mode', 'SOS queued locally', 'Relay simulation shows path'],
  },
  {
    id: 'CROWD_SURGE', icon: '🔴', title: 'Crowd Surge', color: '#EF4444',
    desc: 'Increases crowd density across all zones to RED/ORANGE level.',
    steps: ['All zones updated to higher density', 'RED zones appear on map', 'AI prediction updates', 'Route warnings issued'],
  },
  {
    id: 'FOOD_SHORTAGE', icon: '🍛', title: 'Food Shortage', color: '#F97316',
    desc: 'Marks 5 food centres as unavailable. AI recommends additional resources.',
    steps: ['5 food centres closed', 'AI detects shortage', 'Resource prediction updates', 'Admin alert triggered'],
  },
  {
    id: 'WATER_SHORTAGE', icon: '💧', title: 'Water Shortage', color: '#3B82F6',
    desc: 'Marks 5 water points as empty. Risk levels update.',
    steps: ['5 water points marked EMPTY', 'Water risk level: HIGH', 'Recommendation to refill', 'Map updates'],
  },
  {
    id: 'HEAVY_RAIN', icon: '⛈️', title: 'Heavy Rain Alert', color: '#6366F1',
    desc: 'Triggers weather alert. All Varkaris notified. Route warnings issued.',
    steps: ['Weather alert created', 'Broadcast to all users', 'Route warnings activated', 'Shelter recommendations'],
  },
  {
    id: 'LOST_PERSON', icon: '👤', title: 'Lost Person Case', color: '#EC4899',
    desc: 'Creates a missing person case with QR code.',
    steps: ['Lost person case created', 'QR code generated', 'Alert broadcast', 'Volunteers notified'],
  },
  {
    id: 'RESET', icon: '🔄', title: 'Reset Demo Data', color: '#22C55E',
    desc: 'Resets all demo data back to baseline state.',
    steps: ['Crowd zones normalized', 'Food centres reopened', 'Water points refilled', 'Demo ready again'],
  },
];


export default function DemoControlPanel() {
  const { t, tn } = useLanguage();
  const [results, setResults] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState<Record<string, boolean>>({});
  const [log, setLog] = useState<string[]>([]);

  const triggerEvent = async (eventId: string) => {
    setLoading(prev => ({ ...prev, [eventId]: true }));
    const ts = new Date().toLocaleTimeString();
    try {
      const result = await apiCall('/demo/trigger', {
        method: 'POST',
        body: JSON.stringify({ event_type: eventId }),
      }, getToken());
      setResults(prev => ({ ...prev, [eventId]: result }));
      setLog(prev => [`[${ts}] ✅ ${eventId}: ${result.message || 'Success'}`, ...prev.slice(0, 19)]);
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
            <p style={{ fontSize: '0.75rem', color: '#6B7280' }}>Trigger hackathon demo scenarios in real-time</p>
          </div>
          <span className="badge badge-orange">HACKATHON DEMO MODE</span>
        </header>

        <div className="dashboard-content">
          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.5rem' }}>
            <div>
              {/* Quick Trigger Grid */}
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
                    { label: '🙏 Varkari View', path: '/dashboard/varkari' },
                  ].map(link => (
                    <a key={link.path} href={link.path} className="btn btn-secondary btn-sm" style={{ justifyContent: 'flex-start' }}>
                      {link.label}
                    </a>
                  ))}
                </div>
              </div>

              <div className="card" style={{ marginTop: '1rem', background: '#0F172A', color: 'white' }}>
                <div style={{ fontSize: '0.7rem', color: '#FB923C', fontWeight: 700, marginBottom: '0.5rem' }}>
                  🎭 DEMO DATA NOTICE
                </div>
                <p style={{ fontSize: 'p0.75rem', color: '#9CA3AF', lineHeight: 1.5 }}>
                  All data is simulated for hackathon demonstration. Crowd counts, predictions, and locations are DEMO DATA only.
                </p>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
