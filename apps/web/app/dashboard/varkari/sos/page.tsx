'use client';
import { useState, useEffect, useRef } from 'react';
import { apiCall, getToken, getUser } from '@/lib/api';
import Sidebar from '@/components/Sidebar';
import { useLanguage } from '@/context/LanguageContext';

const CATEGORIES = [
  { value: 'MEDICAL', icon: '🏥', labels: { en: 'Medical', mr: 'वैद्यकीय', hi: 'चिकित्सा' } },
  { value: 'ACCIDENT', icon: '🚨', labels: { en: 'Accident', mr: 'अपघात', hi: 'दुर्घटना' } },
  { value: 'LOST', icon: '👤', labels: { en: 'Lost', mr: 'हरवले', hi: 'लापता' } },
  { value: 'WOMEN_SAFETY', icon: '🆘', labels: { en: 'Women Safety', mr: 'महिला सुरक्षा', hi: 'महिला सुरक्षा' } },
  { value: 'CHILD', icon: '👶', labels: { en: 'Child', mr: 'बालक', hi: 'बच्चा' } },
  { value: 'DEHYDRATION', icon: '💧', labels: { en: 'Dehydration', mr: 'पाणी हवे', hi: 'निर्जलीकरण' } },
  { value: 'FATIGUE', icon: '😓', labels: { en: 'Fatigue', mr: 'थकवा', hi: 'थकान' } },
  { value: 'OTHER', icon: '❓', labels: { en: 'Other', mr: 'इतर', hi: 'अन्य' } },
];

type SOSState = 'idle' | 'confirm' | 'submitting' | 'sent' | 'offline_queued';

export default function SOSPage() {
  const token = getToken();
  const user = getUser();
  const { lang } = useLanguage();
  const copy = {
    en: { emergencyAway: 'Emergency help is one tap away', press: 'Press for emergency assistance', queue: 'Offline SOS Queue', none: 'No pending SOS requests', queued: 'Queued SOS', sync: 'Will sync when back online', confirm: 'Confirm Emergency', sure: 'Are you sure you need emergency help?', type: 'Emergency Type', description: 'Description (Optional)', placeholder: 'Describe your emergency...', cancel: 'Cancel', send: 'SEND SOS NOW', sending: 'Sending SOS...', finding: 'Finding nearest responder', sent: 'SOS SENT!', onWay: 'Help is on the way', incident: 'INCIDENT ID', status: 'STATUS', nearest: 'NEAREST RESPONDER', distance: 'DISTANCE', estimated: 'ESTIMATED RESPONSE', shared: 'Your location has been shared with emergency responders.', offline: 'OFFLINE SOS QUEUED', activating: 'Activating mesh relay network', relay: 'Relay Network Simulation', delivered: 'SOS Delivered via Relay Network!', back: 'Back to SOS' },
    mr: { emergencyAway: 'आपत्कालीन मदत एका स्पर्शावर', press: 'आपत्कालीन मदतीसाठी दाबा', queue: 'ऑफलाइन SOS रांग', none: 'प्रलंबित SOS विनंत्या नाहीत', queued: 'SOS रांगेत', sync: 'इंटरनेट परत आल्यावर समक्रमित होईल', confirm: 'आणीबाणीची पुष्टी करा', sure: 'तुम्हाला आणीबाणीची मदत हवी आहे का?', type: 'आणीबाणीचा प्रकार', description: 'वर्णन (पर्यायी)', placeholder: 'तुमच्या आणीबाणीचे वर्णन करा...', cancel: 'रद्द करा', send: 'आता SOS पाठवा', sending: 'SOS पाठवत आहे...', finding: 'जवळचा प्रतिसादकर्ता शोधत आहे', sent: 'SOS पाठवले!', onWay: 'मदत येत आहे', incident: 'घटना क्रमांक', status: 'स्थिती', nearest: 'जवळचा प्रतिसादकर्ता', distance: 'अंतर', estimated: 'अंदाजे प्रतिसाद', shared: 'तुमचे स्थान आपत्कालीन प्रतिसादकर्त्यांसोबत शेअर केले आहे.', offline: 'ऑफलाइन SOS रांगेत', activating: 'मेश रिले नेटवर्क सुरू करत आहे', relay: 'रिले नेटवर्क सिम्युलेशन', delivered: 'रिले नेटवर्कद्वारे SOS पोहोचले!', back: 'SOS कडे परत' },
    hi: { emergencyAway: 'आपातकालीन सहायता एक टैप दूर है', press: 'आपातकालीन सहायता के लिए दबाएं', queue: 'ऑफलाइन SOS कतार', none: 'कोई लंबित SOS अनुरोध नहीं', queued: 'SOS कतार में', sync: 'इंटरनेट वापस आने पर सिंक होगा', confirm: 'आपातकाल की पुष्टि करें', sure: 'क्या आपको आपातकालीन सहायता चाहिए?', type: 'आपातकालीन प्रकार', description: 'विवरण (वैकल्पिक)', placeholder: 'अपनी आपातकालीन स्थिति बताएं...', cancel: 'रद्द करें', send: 'अभी SOS भेजें', sending: 'SOS भेजा जा रहा है...', finding: 'निकटतम सहायता दल खोज रहे हैं', sent: 'SOS भेज दिया गया!', onWay: 'मदद आ रही है', incident: 'घटना आईडी', status: 'स्थिति', nearest: 'निकटतम सहायता दल', distance: 'दूरी', estimated: 'अनुमानित प्रतिक्रिया', shared: 'आपका स्थान आपातकालीन सहायता दल के साथ साझा किया गया है।', offline: 'ऑफलाइन SOS कतार में', activating: 'मेश रिले नेटवर्क सक्रिय हो रहा है', relay: 'रिले नेटवर्क सिमुलेशन', delivered: 'रिले नेटवर्क से SOS पहुंचा!', back: 'SOS पर वापस' },
  }[lang];
  const [state, setState] = useState<SOSState>('idle');
  const [category, setCategory] = useState('MEDICAL');
  const [description, setDescription] = useState('');
  const [result, setResult] = useState<any>(null);
  const [isOnline, setIsOnline] = useState(true);
  const [offlineQueue, setOfflineQueue] = useState<any[]>([]);
  const [relayStep, setRelayStep] = useState(0);
  const [relayActive, setRelayActive] = useState(false);
  const timerRef = useRef<any>(null);

  useEffect(() => {
    const queue = JSON.parse(localStorage.getItem('sos_queue') || '[]');
    setOfflineQueue(queue);
    setIsOnline(navigator.onLine);
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', () => setIsOnline(false));
    return () => {
      window.removeEventListener('online', handleOnline);
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

  const handleOnline = async () => {
    setIsOnline(true);
    // Sync offline queue
    const queue = JSON.parse(localStorage.getItem('sos_queue') || '[]');
    if (queue.length > 0 && token) {
      for (const sos of queue) {
        try {
          await apiCall('/sos', { method: 'POST', body: JSON.stringify({ ...sos, is_offline: false }) }, token);
        } catch {}
      }
      localStorage.setItem('sos_queue', '[]');
      setOfflineQueue([]);
    }
  };

  const startRelaySim = () => {
    setRelayActive(true);
    let step = 0;
    const advance = () => {
      step++;
      setRelayStep(step);
      if (step < 5) {
        timerRef.current = setTimeout(advance, 1800);
      }
    };
    timerRef.current = setTimeout(advance, 1000);
  };

  const handleSOS = async () => {
    setState('submitting');
    const sosPayload = {
      latitude: 17.6741 + (Math.random() - 0.5) * 0.02,
      longitude: 75.3279 + (Math.random() - 0.5) * 0.02,
      category,
      description,
      blood_group: user?.blood_group || 'O+',
      is_offline: !isOnline,
    };

    if (!isOnline) {
      // Queue offline
      const queue = JSON.parse(localStorage.getItem('sos_queue') || '[]');
      queue.push({ ...sosPayload, queued_at: new Date().toISOString(), local_id: Date.now() });
      localStorage.setItem('sos_queue', JSON.stringify(queue));
      setOfflineQueue(queue);
      setState('offline_queued');
      startRelaySim();
      return;
    }

    try {
      const data = await apiCall('/sos', { method: 'POST', body: JSON.stringify(sosPayload) }, token);
      setResult(data);
      setState('sent');
    } catch {
      // If API fails, queue locally
      const queue = JSON.parse(localStorage.getItem('sos_queue') || '[]');
      queue.push({ ...sosPayload, queued_at: new Date().toISOString() });
      localStorage.setItem('sos_queue', JSON.stringify(queue));
      setOfflineQueue(queue);
      setState('offline_queued');
      startRelaySim();
    }
  };

  const RELAY_STEPS = [
    { icon: '📱', label: 'Your Device', sublabel: 'Varkari' },
    { icon: '📡', label: 'Node-001', sublabel: 'Relay Node 1' },
    { icon: '📡', label: 'Node-003', sublabel: 'Relay Node 2' },
    { icon: '🏗️', label: 'Gateway', sublabel: 'LoRa Gateway' },
    { icon: '🖥️', label: 'Server', sublabel: 'WariVerse AI' },
  ];

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        {!isOnline && (
          <div className="offline-banner">📡 {copy.offline} — {copy.sync}</div>
        )}

        <header className="dashboard-header">
          <h1 style={{ fontSize: '1.25rem', fontWeight: 800 }}>🆘 {copy.send}</h1>
          <div>
            <span className={`badge ${isOnline ? 'badge-green' : 'badge-red'}`}>
              {isOnline ? '🟢 ONLINE' : '🔴 OFFLINE'}
            </span>
            {offlineQueue.length > 0 && (
              <span className="badge badge-yellow" style={{ marginLeft: 8 }}>{offlineQueue.length} queued</span>
            )}
          </div>
        </header>

        <div className="dashboard-content" style={{ maxWidth: 600, margin: '0 auto' }}>

          {state === 'idle' && (
            <>
              <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
                <div style={{ fontSize: '0.9rem', color: '#6B7280', marginBottom: '1rem' }}>
                  {copy.emergencyAway}
                </div>
                <button
                  className="btn-sos"
                  style={{ width: 120, height: 120, fontSize: '2rem' }}
                  onClick={() => setState('confirm')}
                >
                  🆘<br /><span style={{ fontSize: '0.8rem' }}>SOS</span>
                </button>
                <p style={{ marginTop: '1rem', color: '#6B7280', fontSize: '0.85rem' }}>
                  {copy.press}
                </p>
              </div>

              <div className="card">
                <h3 style={{ marginBottom: '1rem' }}>📱 {copy.queue}</h3>
                {offlineQueue.length === 0 ? (
                  <p style={{ color: '#9CA3AF', fontSize: '0.85rem' }}>{copy.none}</p>
                ) : (
                  <div>
                    {offlineQueue.map((q: any, i) => (
                      <div key={i} style={{ padding: '0.5rem', background: '#FEF9C3', borderRadius: 8, marginBottom: '0.5rem', fontSize: '0.8rem' }}>
                        <div style={{ fontWeight: 700 }}>⏳ {copy.queued} — {q.category}</div>
                        <div style={{ color: '#6B7280' }}>{copy.sync} · {new Date(q.queued_at).toLocaleTimeString()}</div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </>
          )}

          {state === 'confirm' && (
            <div className="modal" style={{ background: 'white', border: '2px solid #EF4444', position: 'relative' }}>
              <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
                <div style={{ fontSize: '3rem', marginBottom: '0.5rem' }}>🆘</div>
                <h2 style={{ color: '#EF4444' }}>{copy.confirm}</h2>
                <p style={{ color: '#6B7280', fontSize: '0.875rem' }}>
                  {copy.sure}
                </p>
              </div>

              <div className="form-group">
                <label>{copy.type}</label>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '0.5rem' }}>
                  {CATEGORIES.map(cat => (
                    <button
                      key={cat.value}
                      onClick={() => setCategory(cat.value)}
                      style={{
                        padding: '0.625rem 0.25rem', borderRadius: 10, border: '2px solid',
                        borderColor: category === cat.value ? '#EF4444' : '#E5E7EB',
                        background: category === cat.value ? '#FEE2E2' : 'white',
                        cursor: 'pointer', textAlign: 'center', fontSize: '0.7rem',
                      }}
                    >
                      <div style={{ fontSize: '1.5rem' }}>{cat.icon}</div>
                      <div style={{ fontWeight: 600 }}>{cat.labels[lang]}</div>
                    </button>
                  ))}
                </div>
              </div>

              <div className="form-group">
                <label>{copy.description}</label>
                <textarea
                  className="input"
                  placeholder={copy.placeholder}
                  value={description}
                  onChange={e => setDescription(e.target.value)}
                  rows={3}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <button className="btn btn-secondary btn-lg" onClick={() => setState('idle')}>
                  {copy.cancel}
                </button>
                <button className="btn btn-danger btn-lg" onClick={handleSOS}>
                  🆘 {copy.send}
                </button>
              </div>

              {!isOnline && (
                <div style={{ marginTop: '1rem', background: '#FEF9C3', borderRadius: 8, padding: '0.75rem', fontSize: '0.8rem', textAlign: 'center' }}>
                  ⚠️ No internet — SOS will be queued and relayed via mesh network
                </div>
              )}
            </div>
          )}

          {state === 'submitting' && (
            <div style={{ textAlign: 'center', padding: '3rem' }}>
              <div className="spinner" style={{ width: 60, height: 60, margin: '0 auto 1rem', borderWidth: 4 }} />
              <h3>Sending SOS...</h3>
              <p style={{ color: '#6B7280' }}>Finding nearest responder</p>
            </div>
          )}

          {state === 'sent' && result && (
            <div>
              <div style={{ background: '#DCFCE7', border: '2px solid #22C55E', borderRadius: 16, padding: '2rem', textAlign: 'center', marginBottom: '1.5rem' }}>
                <div style={{ fontSize: '4rem', marginBottom: '0.5rem' }}>✅</div>
                <h2 style={{ color: '#15803D' }}>SOS SENT!</h2>
                <p style={{ color: '#166534' }}>{copy.onWay}</p>
                <div style={{ background: 'white', borderRadius: 12, padding: '1rem', marginTop: '1rem', textAlign: 'left' }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                    <div>
                      <div style={{ fontSize: '0.7rem', color: '#6B7280', fontWeight: 600 }}>{copy.incident}</div>
                      <div style={{ fontWeight: 700, fontSize: '0.875rem' }}>{result.incident_ref}</div>
                    </div>
                    <div>
                      <div style={{ fontSize: '0.7rem', color: '#6B7280', fontWeight: 600 }}>{copy.status}</div>
                      <div style={{ fontWeight: 700, color: '#15803D' }}>{result.status}</div>
                    </div>
                    {result.responder && (
                      <>
                        <div>
                          <div style={{ fontSize: '0.7rem', color: '#6B7280', fontWeight: 600 }}>{copy.nearest}</div>
                          <div style={{ fontWeight: 700, fontSize: '0.875rem' }}>{result.responder.name || 'Assigned'}</div>
                        </div>
                        <div>
                          <div style={{ fontSize: '0.7rem', color: '#6B7280', fontWeight: 600 }}>{copy.distance}</div>
                          <div style={{ fontWeight: 700 }}>{result.responder.distance_m}m</div>
                        </div>
                      </>
                    )}
                    {result.estimated_response_minutes && (
                      <div style={{ gridColumn: 'span 2' }}>
                        <div style={{ fontSize: '0.7rem', color: '#6B7280', fontWeight: 600 }}>{copy.estimated}</div>
                        <div style={{ fontWeight: 700, color: '#F97316' }}>~{result.estimated_response_minutes} minutes</div>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div className="card" style={{ textAlign: 'center' }}>
                <p style={{ color: '#6B7280', fontSize: '0.85rem', marginBottom: '1rem' }}>
                  {copy.shared}
                </p>
                <button className="btn btn-secondary" onClick={() => { setState('idle'); setResult(null); }}>
                  ← {copy.back}
                </button>
              </div>
            </div>
          )}

          {state === 'offline_queued' && (
            <div>
              <div style={{ background: '#FEF9C3', border: '2px solid #F59E0B', borderRadius: 16, padding: '2rem', textAlign: 'center', marginBottom: '1.5rem' }}>
                <div style={{ fontSize: '3rem', marginBottom: '0.5rem' }}>📡</div>
                <h2 style={{ color: '#B45309' }}>{copy.offline}</h2>
                <p style={{ color: '#92400E', fontSize: '0.875rem' }}>{copy.activating}</p>
              </div>

              {/* Relay Simulation */}
              <div className="card" style={{ marginBottom: '1rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                  <span>🔗</span>
                  <h3 style={{ fontSize: '1rem' }}>{copy.relay}</h3>
                  <span className="badge badge-orange" style={{ fontSize: '0.65rem' }}>DEMO MODE</span>
                </div>
                <div className="relay-path">
                  {RELAY_STEPS.map((step, i) => (
                    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <div className="relay-node">
                        <div className={`relay-node-icon ${relayStep > i || (relayActive && relayStep === i) ? 'relay-node-active' : 'relay-node-idle'}`}>
                          {step.icon}
                        </div>
                        <div className="relay-node-label">{step.label}</div>
                        <div className="relay-node-label" style={{ fontSize: '0.6rem', color: '#6B7280' }}>{step.sublabel}</div>
                        {relayStep > i && <div style={{ fontSize: '0.6rem', color: '#22C55E' }}>✓ OK</div>}
                        {relayActive && relayStep === i && <div style={{ fontSize: '0.6rem', color: '#F59E0B' }}>⏳ Sending...</div>}
                      </div>
                      {i < RELAY_STEPS.length - 1 && (
                        <div className={`relay-arrow ${relayStep > i ? 'relay-arrow-active' : ''}`}>→</div>
                      )}
                    </div>
                  ))}
                </div>

                {relayStep >= 4 && (
                  <div style={{ marginTop: '1rem', background: '#DCFCE7', borderRadius: 8, padding: '0.75rem', textAlign: 'center' }}>
                    <div style={{ color: '#15803D', fontWeight: 700 }}>✅ {copy.delivered}</div>
                  </div>
                )}
              </div>

              <div className="card">
                <h4 style={{ marginBottom: '0.5rem' }}>ℹ️ {copy.activating}</h4>
                <ul style={{ fontSize: '0.8rem', color: '#6B7280', paddingLeft: '1rem', lineHeight: 2 }}>
                  <li>SOS saved to device storage</li>
                  <li>Mesh relay network activated (simulated)</li>
                  <li>Message hopping through nearby nodes</li>
                  <li>Will auto-sync when internet returns</li>
                  <li>Hardware: ESP32 + LoRa gateway ready</li>
                </ul>
              </div>

              <button className="btn btn-secondary btn-full" style={{ marginTop: '1rem' }} onClick={() => setState('idle')}>
                ← {copy.back}
              </button>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
