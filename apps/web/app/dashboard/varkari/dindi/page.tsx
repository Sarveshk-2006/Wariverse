'use client';
import { useState, useEffect } from 'react';
import { apiCall, getToken, getUser } from '@/lib/api';
import Sidebar from '@/components/Sidebar';
import { useLanguage } from '@/context/LanguageContext';

const HALT_TYPE_ICONS: Record<string, string> = {
  DEPARTURE: '🌅',
  BREAKFAST: '🍵',
  LUNCH: '🍛',
  RINGAN: '🎪',
  NIGHT_SHELTER: '🏕️',
  TEMPLE: '🛕',
};

const SAMPLE_ABHANGS = [
  {
    title: 'आनंदाचे डोही आनंद तरंग',
    author: 'संत तुकाराम महाराज',
    lyrics: 'आनंदाचे डोही आनंद तरंग । आनंदचि अंग जिवाचिया ॥\nकाय सांगो सुख जाहले आवडी । वाढलीये गोडी प्रेमाचि पै ॥\nविठ्ठल रुक्मिणी नामस्मरण करू । पंढरीची वाट आनंदाने चालू ॥'
  },
  {
    title: 'रूप पाहता लोचनी',
    author: 'संत ज्ञानेश्वर माऊली',
    lyrics: 'रूप पाहता लोचनी । सुख जाहले वो साजणी ॥\nतो हा विठ्ठल बरवा । तो हा माधव बरवा ॥\nबहुतां सुकृतांची जोडी । म्हणूनि विठ्ठलीं आवडी ॥'
  },
  {
    title: 'माझे माहेर पंढरी',
    author: 'संत एकनाथ महाराज',
    lyrics: 'माझे माहेर पंढरी । आहे भिवरेच्या तीरी ॥\nबाप आणि आई । माझी विठ्ठल रखुमाई ॥'
  }
];

export default function VarkariDindiPage() {
  const token = getToken();
  const user = getUser();
  const { lang } = useLanguage();

  const [dindis, setDindis] = useState<any[]>([]);
  const [selectedDindi, setSelectedDindi] = useState<any>(null);
  const [schedule, setSchedule] = useState<any[]>([]);
  const [posts, setPosts] = useState<any[]>([]);
  const [healthShield, setHealthShield] = useState<any>(null);
  const [audioStream, setAudioStream] = useState<any>(null);

  const [activeTab, setActiveTab] = useState<'schedule' | 'feed' | 'audio' | 'badge'>('schedule');
  const [selectedDay, setSelectedDay] = useState<number>(1);
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [showPrintModal, setShowPrintModal] = useState(false);
  const [qrInput, setQrInput] = useState('');
  const [postMessage, setPostMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [selectedAbhang, setSelectedAbhang] = useState<any>(null);

  useEffect(() => {
    loadInitialData();
  }, []);

  const loadInitialData = async () => {
    try {
      const dList = await apiCall('/dindi/list');
      setDindis(dList);
      if (dList.length > 0) {
        selectDindi(dList[0]);
      }
      const hsData = await apiCall('/health-shield/check');
      setHealthShield(hsData);
    } catch {}
    setLoading(false);
  };

  const selectDindi = async (dindiObj: any) => {
    setSelectedDindi(dindiObj);
    try {
      const sch = await apiCall(`/dindi/${dindiObj.id}/schedule`);
      setSchedule(sch);
      const pst = await apiCall(`/dindi/${dindiObj.id}/posts`);
      setPosts(pst);
      const audio = await apiCall(`/dindi/${dindiObj.id}/audio`);
      setAudioStream(audio);
    } catch {}
  };

  const handleJoinByQR = async () => {
    if (!qrInput.trim()) return;
    setSubmitting(true);
    try {
      const res = await apiCall('/dindi/join-by-qr', {
        method: 'POST',
        body: JSON.stringify({ qr_data: qrInput })
      }, token);
      alert(res.message);
      setSelectedDindi(res.dindi);
      setSchedule(res.halts);
      setShowJoinModal(false);
      setQrInput('');
    } catch (e: any) {
      alert('Error: ' + e.message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleCreatePost = async () => {
    if (!postMessage.trim() || !selectedDindi) return;
    setSubmitting(true);
    try {
      await apiCall(`/dindi/${selectedDindi.id}/posts`, {
        method: 'POST',
        body: JSON.stringify({ message: postMessage, is_announcement: false })
      }, token);
      setPostMessage('');
      const pst = await apiCall(`/dindi/${selectedDindi.id}/posts`);
      setPosts(pst);
    } catch (e: any) {
      alert('Error: ' + e.message);
    } finally {
      setSubmitting(false);
    }
  };

  const days = Array.from(new Set(schedule.map(s => s.day_number))).sort((a, b) => a - b);
  const filteredSchedule = schedule.filter(s => s.day_number === selectedDay);
  const completedCount = schedule.filter(s => s.is_completed).length;
  const progressPct = schedule.length > 0 ? Math.round((completedCount / schedule.length) * 100) : 0;

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 800 }}>🚩 Dindi Ecosystem Hub</h1>
            <p style={{ fontSize: '0.8rem', color: '#6B7280' }}>डिंडी सूक्ष्म-वेळापत्रक, थेट मार्ग आणि समूह संवाद</p>
          </div>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <button className="btn btn-secondary btn-sm" onClick={() => setShowPrintModal(true)}>
              🖨️ Print Schedule
            </button>
            <button className="btn btn-primary btn-sm" onClick={() => setShowJoinModal(true)}>
              📷 Scan / Join Dindi
            </button>
          </div>
        </header>

        <div className="dashboard-content">
          {/* Health Shield Hydration Warning */}
          {healthShield?.hydration_warning && (
            <div style={{ background: '#FEF2F2', border: '2px solid #EF4444', borderRadius: 12, padding: '0.875rem 1rem', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <span style={{ fontSize: '1.75rem' }}>🌡️</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 800, color: '#991B1B', fontSize: '0.9rem' }}>
                  Varkari Health Shield Alert: Heat Index {healthShield.heat_index}°C ({healthShield.risk_level})
                </div>
                <div style={{ fontSize: '0.8rem', color: '#7F1D1D' }}>
                  {healthShield.advice} Drink clean water at the next hydration halt!
                </div>
              </div>
            </div>
          )}

          {/* Dindi Switcher & Selector */}
          <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem', overflowX: 'auto', paddingBottom: '0.25rem' }}>
            {dindis.map(d => (
              <button
                key={d.id}
                className={`btn btn-sm ${selectedDindi?.id === d.id ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => selectDindi(d)}
                style={{ flexShrink: 0 }}
              >
                🚩 {d.name} ({d.code})
              </button>
            ))}
          </div>

          {selectedDindi ? (
            <>
              {/* Selected Dindi Banner Card */}
              <div className="card" style={{ background: 'linear-gradient(135deg, #7C3AED 0%, #4F46E5 100%)', color: 'white', marginBottom: '1.25rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem' }}>
                  <div>
                    <span className="badge" style={{ background: 'rgba(255,255,255,0.2)', color: 'white', fontSize: '0.7rem', marginBottom: '0.5rem' }}>
                      {selectedDindi.code} · {selectedDindi.palkhi_type}
                    </span>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 800, margin: '0.25rem 0' }}>{selectedDindi.name}</h2>
                    <div style={{ fontSize: '0.85rem', opacity: 0.9 }}>
                      🚩 Leader: <strong>{selectedDindi.leader_name}</strong> · 📍 Origin: {selectedDindi.origin} · 👥 {selectedDindi.total_members} Pilgrims
                    </div>
                  </div>
                  <div style={{ textAlign: 'right', display: 'flex', gap: '0.5rem' }}>
                    <button className="btn btn-sm" style={{ background: 'rgba(255,255,255,0.2)', color: 'white', fontWeight: 700 }} onClick={() => setShowPrintModal(true)}>
                      🖨️ Print
                    </button>
                    <button className="btn btn-sm" style={{ background: 'white', color: '#7C3AED', fontWeight: 700 }} onClick={() => setActiveTab('badge')}>
                      🪪 View Digital Pass
                    </button>
                  </div>
                </div>

                {/* Real-time Checkpoint Progress Bar */}
                <div style={{ marginTop: '1.25rem', paddingTop: '1rem', borderTop: '1px solid rgba(255,255,255,0.2)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.375rem' }}>
                    <span>🏁 Checkpoint Progress: {completedCount} of {schedule.length} Halts Completed</span>
                    <span>{progressPct}% Completed</span>
                  </div>
                  <div style={{ width: '100%', height: 8, background: 'rgba(255,255,255,0.25)', borderRadius: 4, overflow: 'hidden' }}>
                    <div style={{ width: `${progressPct}%`, height: '100%', background: '#22C55E', transition: 'width 0.4s ease' }} />
                  </div>
                </div>
              </div>

              {/* Navigation Tabs */}
              <div style={{ display: 'flex', borderBottom: '2px solid #E2E8F0', marginBottom: '1.25rem', gap: '0.5rem' }}>
                {[
                  { id: 'schedule', label: '📅 Micro-Schedule', icon: '⏰' },
                  { id: 'feed', label: '💬 Dindi Group Feed', icon: '📢' },
                  { id: 'audio', label: '🎙️ Live Audio & Abhangs', icon: '🎶' },
                  { id: 'badge', label: '🪪 Digital Dindi Pass', icon: '🎫' },
                ].map(tab => (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id as any)}
                    style={{
                      padding: '0.625rem 1rem',
                      borderBottom: activeTab === tab.id ? '3px solid #7C3AED' : '3px solid transparent',
                      fontWeight: activeTab === tab.id ? 700 : 500,
                      color: activeTab === tab.id ? '#7C3AED' : '#64748B',
                      background: 'none',
                      borderTop: 'none', borderLeft: 'none', borderRight: 'none',
                      cursor: 'pointer', fontSize: '0.875rem'
                    }}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>

              {/* TAB 1: MICRO-SCHEDULE */}
              {activeTab === 'schedule' && (
                <div>
                  {/* Day Filter */}
                  <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem', alignItems: 'center' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#64748B' }}>Select Day:</span>
                    {(days.length > 0 ? days : [1]).map(day => (
                      <button
                        key={day}
                        className={`btn btn-sm ${selectedDay === day ? 'btn-primary' : 'btn-secondary'}`}
                        onClick={() => setSelectedDay(day)}
                      >
                        Day {day}
                      </button>
                    ))}
                  </div>

                  {/* Halts Timeline */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {filteredSchedule.map((halt: any) => (
                      <div key={halt.id} className="card card-sm" style={{ borderLeft: `5px solid ${halt.is_completed ? '#22C55E' : '#7C3AED'}`, position: 'relative' }}>
                        <div style={{ display: 'flex', gap: '1rem', alignItems: 'flex-start' }}>
                          <div style={{ fontSize: '2rem', flexShrink: 0 }}>
                            {HALT_TYPE_ICONS[halt.halt_type] || '📍'}
                          </div>
                          <div style={{ flex: 1 }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
                              <span style={{ fontWeight: 800, fontSize: '0.95rem', color: '#1E293B' }}>{halt.title}</span>
                              <span className={`badge ${halt.is_completed ? 'badge-green' : 'badge-purple'}`}>
                                {halt.is_completed ? '✅ CHECKPOINT CONCLUDED' : `${halt.scheduled_arrival} - ${halt.scheduled_departure}`}
                              </span>
                            </div>
                            <div style={{ fontSize: '0.85rem', color: '#64748B', fontWeight: 600, marginBottom: '0.25rem' }}>
                              📍 {halt.location_name}
                            </div>
                            {halt.notes && (
                              <div style={{ fontSize: '0.8rem', color: '#475569', background: '#F8FAFC', padding: '0.5rem', borderRadius: 8 }}>
                                💡 {halt.notes}
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    ))}
                    {filteredSchedule.length === 0 && (
                      <div style={{ textAlign: 'center', padding: '2rem', color: '#9CA3AF' }}>
                        No halts scheduled for Day {selectedDay}.
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* TAB 2: DINDI GROUP FEED */}
              {activeTab === 'feed' && (
                <div>
                  {/* Create Post Input */}
                  <div className="card" style={{ marginBottom: '1rem' }}>
                    <h3 style={{ fontSize: '0.9rem', fontWeight: 700, marginBottom: '0.5rem' }}>Post to Dindi Group Feed</h3>
                    <textarea
                      className="input"
                      rows={3}
                      placeholder="Share updates with your Dindi members..."
                      value={postMessage}
                      onChange={e => setPostMessage(e.target.value)}
                    />
                    <div style={{ textAlign: 'right', marginTop: '0.5rem' }}>
                      <button className="btn btn-primary btn-sm" onClick={handleCreatePost} disabled={submitting || !postMessage.trim()}>
                        {submitting ? 'Posting...' : '📢 Post Message'}
                      </button>
                    </div>
                  </div>

                  {/* Feed List */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                    {posts.map((p: any) => (
                      <div key={p.id} className="card card-sm" style={{ borderLeft: p.is_announcement ? '4px solid #EF4444' : '4px solid #3B82F6', background: p.is_announcement ? '#FEF2F2' : 'white' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
                          <div style={{ fontWeight: 800, fontSize: '0.85rem', color: p.is_announcement ? '#991B1B' : '#1E293B' }}>
                            {p.author_name} {p.is_announcement && <span className="badge badge-red" style={{ fontSize: '0.65rem' }}>📢 LEADER ANNOUNCEMENT</span>}
                          </div>
                          <span style={{ fontSize: '0.7rem', color: '#9CA3AF' }}>{new Date(p.created_at).toLocaleTimeString()}</span>
                        </div>
                        <p style={{ fontSize: '0.875rem', lineHeight: 1.5, color: '#334155' }}>{p.message}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* TAB 3: LIVE AUDIO & ABHANGAVALI */}
              {activeTab === 'audio' && (
                <div>
                  {/* Live Stream Banner */}
                  <div className="card" style={{ background: '#0F172A', color: 'white', marginBottom: '1.25rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <span className="badge badge-red">🔴 LIVE AUDIO BROADCAST</span>
                        <h3 style={{ fontSize: '1rem', fontWeight: 800, marginTop: '0.5rem' }}>
                          {audioStream?.is_live ? audioStream.title : 'Live Kirtan & Abhang Stream'}
                        </h3>
                        <p style={{ fontSize: '0.8rem', color: '#94A3B8' }}>Listen to live leadership announcements and bhajans over Dindi speaker network.</p>
                      </div>
                      <button className="btn btn-primary" onClick={() => alert('Playing live WebRTC audio stream...')}>
                        ▶️ Listen Live
                      </button>
                    </div>
                  </div>

                  {/* Abhangavali Hymnbook */}
                  <h3 style={{ fontSize: '1rem', fontWeight: 800, marginBottom: '0.75rem', color: '#1E293B' }}>📖 Digital Abhangavali (Offline Hymnbook)</h3>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem' }}>
                    {SAMPLE_ABHANGS.map((abhang, i) => (
                      <div key={i} className="card card-sm" style={{ cursor: 'pointer' }} onClick={() => setSelectedAbhang(abhang)}>
                        <div style={{ fontWeight: 800, fontSize: '0.9rem', color: '#7C3AED', marginBottom: '0.25rem' }}>{abhang.title}</div>
                        <div style={{ fontSize: '0.75rem', color: '#64748B', marginBottom: '0.5rem' }}>{abhang.author}</div>
                        <p style={{ fontSize: '0.8rem', whiteSpace: 'pre-line', color: '#334155', height: 75, overflow: 'hidden' }}>{abhang.lyrics}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* TAB 4: DIGITAL DINDI PASS */}
              {activeTab === 'badge' && (
                <div className="card" style={{ maxWidth: 450, margin: '0 auto', border: '2px solid #7C3AED', borderRadius: 16, background: '#FAF5FF', textAlign: 'center', padding: '2rem' }}>
                  <div style={{ fontSize: '0.8rem', fontWeight: 800, color: '#7C3AED', letterSpacing: '1px' }}>OFFICIAL DINDI MEMBER PASS</div>
                  <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#1E293B', margin: '0.5rem 0' }}>{user?.display_name || 'Varkari Pilgrim'}</h2>
                  <div className="badge badge-purple" style={{ fontSize: '0.75rem', marginBottom: '1rem' }}>
                    {selectedDindi.name} ({selectedDindi.code})
                  </div>

                  {/* QR Code Container */}
                  <div style={{ background: 'white', padding: '1.5rem', borderRadius: 16, border: '1px solid #E9D5FF', display: 'inline-block', margin: '1rem 0' }}>
                    <div style={{ fontSize: '4rem', lineHeight: 1 }}>📱</div>
                    <div style={{ fontSize: '0.75rem', fontFamily: 'monospace', color: '#6B7280', marginTop: '0.5rem' }}>{selectedDindi.qr_code_data}</div>
                  </div>

                  <div style={{ fontSize: '0.8rem', color: '#64748B', textAlign: 'left', background: 'white', padding: '0.875rem', borderRadius: 8, marginTop: '1rem' }}>
                    <div><strong>Leader:</strong> {selectedDindi.leader_name}</div>
                    <div><strong>Origin:</strong> {selectedDindi.origin}</div>
                    <div><strong>Blood Group:</strong> {user?.blood_group || 'O+'}</div>
                  </div>
                </div>
              )}
            </>
          ) : (
            <div style={{ textAlign: 'center', padding: '3rem', color: '#9CA3AF' }}>
              <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🚩</div>
              <p>No Dindi selected. Select a Dindi above or scan a QR code to join!</p>
            </div>
          )}
        </div>

        {/* Printable Schedule Modal */}
        {showPrintModal && selectedDindi && (
          <div className="modal-overlay" onClick={() => setShowPrintModal(false)}>
            <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 700, padding: '2rem' }}>
              <div id="printable-area">
                <div style={{ textAlign: 'center', borderBottom: '2px solid #7C3AED', paddingBottom: '1rem', marginBottom: '1.5rem' }}>
                  <div style={{ fontSize: '2rem' }}>🚩</div>
                  <h1 style={{ fontSize: '1.5rem', fontWeight: 800, color: '#7C3AED', margin: '0.25rem 0' }}>{selectedDindi.name}</h1>
                  <div style={{ fontSize: '0.9rem', color: '#475569', fontWeight: 600 }}>
                    Official Wari Itinerary · {selectedDindi.code} · Leader: {selectedDindi.leader_name}
                  </div>
                </div>

                <div style={{ marginBottom: '1.5rem' }}>
                  <h3 style={{ fontSize: '1rem', fontWeight: 800, marginBottom: '0.75rem', color: '#1E293B' }}>📅 Complete Day-by-Day Procession Schedule</h3>
                  <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
                    <thead>
                      <tr style={{ background: '#F1F5F9', borderBottom: '2px solid #CBD5E1', textAlign: 'left' }}>
                        <th style={{ padding: '0.5rem' }}>Day</th>
                        <th style={{ padding: '0.5rem' }}>Timings</th>
                        <th style={{ padding: '0.5rem' }}>Type</th>
                        <th style={{ padding: '0.5rem' }}>Halt Title & Location</th>
                        <th style={{ padding: '0.5rem' }}>Notes</th>
                      </tr>
                    </thead>
                    <tbody>
                      {schedule.map((h: any) => (
                        <tr key={h.id} style={{ borderBottom: '1px solid #E2E8F0' }}>
                          <td style={{ padding: '0.5rem', fontWeight: 700 }}>Day {h.day_number}</td>
                          <td style={{ padding: '0.5rem' }}>{h.scheduled_arrival} - {h.scheduled_departure}</td>
                          <td style={{ padding: '0.5rem' }}>{HALT_TYPE_ICONS[h.halt_type]} {h.halt_type}</td>
                          <td style={{ padding: '0.5rem', fontWeight: 600 }}>{h.title} <br/><span style={{ color: '#64748B', fontSize: '0.75rem' }}>📍 {h.location_name}</span></td>
                          <td style={{ padding: '0.5rem', fontSize: '0.75rem', color: '#475569' }}>{h.notes || '-'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#FAF5FF', padding: '1rem', borderRadius: 8, border: '1px solid #E9D5FF' }}>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.85rem', color: '#7C3AED' }}>Scan to Join Dindi on WariVerse App</div>
                    <div style={{ fontSize: '0.75rem', color: '#64748B', fontFamily: 'monospace' }}>{selectedDindi.qr_code_data}</div>
                  </div>
                  <div style={{ fontSize: '2rem' }}>📱</div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem', marginTop: '1.5rem' }}>
                <button className="btn btn-secondary" onClick={() => setShowPrintModal(false)}>Close</button>
                <button className="btn btn-primary" onClick={handlePrint}>🖨️ Print Now</button>
              </div>
            </div>
          </div>
        )}

        {/* Join Dindi Modal */}
        {showJoinModal && (
          <div className="modal-overlay" onClick={() => setShowJoinModal(false)}>
            <div className="modal" onClick={e => e.stopPropagation()}>
              <h2 style={{ marginBottom: '0.5rem', color: '#7C3AED' }}>📷 Scan / Join Dindi</h2>
              <p style={{ color: '#64748B', fontSize: '0.85rem', marginBottom: '1.25rem' }}>Enter Dindi Shortcode (e.g. DINDI-TUKARAM-01) or scan QR code payload.</p>
              <div className="form-group">
                <label>Dindi Code or QR Token</label>
                <input
                  className="input"
                  placeholder="Enter shortcode e.g. DINDI-TUKARAM-01"
                  value={qrInput}
                  onChange={e => setQrInput(e.target.value)}
                />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginTop: '1.5rem' }}>
                <button className="btn btn-secondary" onClick={() => setShowJoinModal(false)}>Cancel</button>
                <button className="btn btn-primary" onClick={handleJoinByQR} disabled={submitting || !qrInput.trim()}>
                  {submitting ? 'Joining...' : '✓ Join Dindi'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Abhang Lyric Modal */}
        {selectedAbhang && (
          <div className="modal-overlay" onClick={() => setSelectedAbhang(null)}>
            <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 500 }}>
              <h2 style={{ color: '#7C3AED', marginBottom: '0.25rem' }}>{selectedAbhang.title}</h2>
              <div style={{ fontSize: '0.85rem', color: '#64748B', marginBottom: '1rem' }}>{selectedAbhang.author}</div>
              <div style={{ fontSize: '1rem', lineHeight: 1.8, whiteSpace: 'pre-line', background: '#F8FAFC', padding: '1.25rem', borderRadius: 12, color: '#1E293B', fontWeight: 600 }}>
                {selectedAbhang.lyrics}
              </div>
              <button className="btn btn-secondary btn-full" style={{ marginTop: '1.5rem' }} onClick={() => setSelectedAbhang(null)}>Close</button>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
