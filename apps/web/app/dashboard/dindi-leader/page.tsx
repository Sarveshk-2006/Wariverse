'use client';
import { useState, useEffect } from 'react';
import { apiCall, getToken, getUser } from '@/lib/api';
import Sidebar from '@/components/Sidebar';

export default function DindiLeaderDashboardPage() {
  const token = getToken();
  const user = getUser();

  const [dindis, setDindis] = useState<any[]>([]);
  const [selectedDindi, setSelectedDindi] = useState<any>(null);
  const [schedule, setSchedule] = useState<any[]>([]);
  const [posts, setPosts] = useState<any[]>([]);
  const [isBeaconActive, setIsBeaconActive] = useState(false);

  const [showAddHalt, setShowAddHalt] = useState(false);
  const [haltDay, setHaltDay] = useState(1);
  const [haltType, setHaltType] = useState('LUNCH');
  const [haltTitle, setHaltTitle] = useState('');
  const [haltLocation, setHaltLocation] = useState('');
  const [haltArr, setHaltArr] = useState('12:00');
  const [haltDep, setHaltDep] = useState('13:30');
  const [haltNotes, setHaltNotes] = useState('');

  const [announcementMsg, setAnnouncementMsg] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadLeaderDindi();
  }, []);

  const loadLeaderDindi = async () => {
    try {
      const dList = await apiCall('/dindi/list');
      setDindis(dList);
      if (dList.length > 0) {
        selectDindi(dList[0]);
      }
    } catch {}
  };

  const selectDindi = async (dindiObj: any) => {
    setSelectedDindi(dindiObj);
    setIsBeaconActive(dindiObj.is_beacon_active || false);
    try {
      const sch = await apiCall(`/dindi/${dindiObj.id}/schedule`);
      setSchedule(sch);
      const pst = await apiCall(`/dindi/${dindiObj.id}/posts`);
      setPosts(pst);
    } catch {}
  };

  const toggleBeacon = async () => {
    if (!selectedDindi) return;
    const nextState = !isBeaconActive;
    setIsBeaconActive(nextState);
    try {
      await apiCall(`/dindi/${selectedDindi.id}/location`, {
        method: 'POST',
        body: JSON.stringify({ latitude: 18.5204, longitude: 73.8567 })
      }, token);
      alert(nextState ? '📡 Live GPS Beacon Activated! Transmitting location to members.' : 'Beacon Deactivated.');
    } catch {}
  };

  const markHaltCompleted = async (halt: any) => {
    if (!selectedDindi) return;
    try {
      // Toggle completed state
      const updatedSchedule = schedule.map(h => h.id === halt.id ? { ...h, is_completed: true } : h);
      setSchedule(updatedSchedule);

      // Auto-broadcast checkpoint conclusion alert
      const autoBroadcastMsg = `✅ Checkpoint Concluded: ${halt.title} (${halt.location_name}) completed. Procession resuming march to next destination.`;
      await apiCall(`/dindi/${selectedDindi.id}/posts`, {
        method: 'POST',
        body: JSON.stringify({ message: autoBroadcastMsg, is_announcement: true, post_type: 'ANNOUNCEMENT' })
      }, token);

      const pst = await apiCall(`/dindi/${selectedDindi.id}/posts`);
      setPosts(pst);
      alert(`✅ Checkpoint "${halt.title}" marked as CONCLUDED & broadcasted to all members!`);
    } catch (e: any) {
      alert('Error concluding checkpoint: ' + e.message);
    }
  };

  const handleAddHalt = async () => {
    if (!haltTitle.trim() || !haltLocation.trim() || !selectedDindi) return;
    setSubmitting(true);
    try {
      await apiCall(`/dindi/${selectedDindi.id}/schedule`, {
        method: 'POST',
        body: JSON.stringify({
          day_number: haltDay,
          halt_type: haltType,
          title: haltTitle,
          location_name: haltLocation,
          latitude: 18.5204,
          longitude: 73.8567,
          scheduled_arrival: haltArr,
          scheduled_departure: haltDep,
          notes: haltNotes
        })
      }, token);
      setShowAddHalt(false);
      setHaltTitle('');
      setHaltLocation('');
      setHaltNotes('');
      const sch = await apiCall(`/dindi/${selectedDindi.id}/schedule`);
      setSchedule(sch);
    } catch (e: any) {
      alert('Error adding halt: ' + e.message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleBroadcastAnnouncement = async () => {
    if (!announcementMsg.trim() || !selectedDindi) return;
    setSubmitting(true);
    try {
      await apiCall(`/dindi/${selectedDindi.id}/posts`, {
        method: 'POST',
        body: JSON.stringify({ message: announcementMsg, is_announcement: true, post_type: 'ANNOUNCEMENT' })
      }, token);
      setAnnouncementMsg('');
      const pst = await apiCall(`/dindi/${selectedDindi.id}/posts`);
      setPosts(pst);
      alert('📢 Announcement broadcasted to all Dindi members!');
    } catch (e: any) {
      alert('Error broadcasting: ' + e.message);
    } finally {
      setSubmitting(false);
    }
  };

  const completedCount = schedule.filter(s => s.is_completed).length;

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 800 }}>👑 Dindi Leader Management Dashboard</h1>
            <p style={{ fontSize: '0.8rem', color: '#6B7280' }}>डिंडी प्रमुख नियंत्रण कक्ष — वेळापत्रक आणि थेट संदेश</p>
          </div>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <button
              className={`btn btn-sm ${isBeaconActive ? 'btn-danger' : 'btn-primary'}`}
              onClick={toggleBeacon}
            >
              {isBeaconActive ? '🔴 Stop GPS Beacon' : '📡 Start Live GPS Beacon'}
            </button>
          </div>
        </header>

        <div className="dashboard-content">
          {/* Dindi Selector */}
          <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1.25rem' }}>
            {dindis.map(d => (
              <button
                key={d.id}
                className={`btn btn-sm ${selectedDindi?.id === d.id ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => selectDindi(d)}
              >
                🚩 {d.name} ({d.code})
              </button>
            ))}
          </div>

          {selectedDindi && (
            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.5rem' }}>
              {/* Left Column: Schedule & Broadcast */}
              <div>
                {/* Broadcast Announcement Box */}
                <div className="card" style={{ borderLeft: '4px solid #7C3AED', marginBottom: '1.25rem' }}>
                  <h3 style={{ fontSize: '0.95rem', fontWeight: 800, color: '#7C3AED', marginBottom: '0.5rem' }}>
                    📢 Send Leader Broadcast Notice
                  </h3>
                  <p style={{ fontSize: '0.8rem', color: '#64748B', marginBottom: '0.75rem' }}>
                    Pushes a high-priority pinned alert to all enrolled members' private Dindi feeds.
                  </p>
                  <textarea
                    className="input"
                    rows={3}
                    placeholder="e.g. माऊलींचे प्रस्थान २० मिनिटे उशिरा होईल. सर्वांनी मंदिराजवळ जमावे."
                    value={announcementMsg}
                    onChange={e => setAnnouncementMsg(e.target.value)}
                  />
                  <div style={{ textAlign: 'right', marginTop: '0.5rem' }}>
                    <button className="btn btn-primary btn-sm" onClick={handleBroadcastAnnouncement} disabled={submitting || !announcementMsg.trim()}>
                      {submitting ? 'Broadcasting...' : '📡 Broadcast to Members'}
                    </button>
                  </div>
                </div>

                {/* Itinerary Schedule & Checkpoint Management */}
                <div className="card">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                    <div>
                      <h3 style={{ fontSize: '1rem', fontWeight: 800, margin: 0 }}>🏁 Checkpoint & Halt Management</h3>
                      <div style={{ fontSize: '0.8rem', color: '#64748B', marginTop: '0.25rem' }}>
                        Progress: {completedCount} of {schedule.length} Checkpoints Concluded
                      </div>
                    </div>
                    <button className="btn btn-primary btn-sm" onClick={() => setShowAddHalt(true)}>
                      + Add Halt / Stop
                    </button>
                  </div>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                    {schedule.map((halt: any) => (
                      <div key={halt.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.875rem', border: '1px solid #E2E8F0', borderRadius: 10, background: halt.is_completed ? '#F0FDF4' : '#F8FAFC' }}>
                        <div>
                          <div style={{ fontWeight: 800, fontSize: '0.9rem', color: '#1E293B', display: 'flex', alignItems: 'center', gap: '0.375rem' }}>
                            [Day {halt.day_number}] {halt.title} ({halt.halt_type})
                            {halt.is_completed && <span className="badge badge-green">✓ CONCLUDED</span>}
                          </div>
                          <div style={{ fontSize: '0.8rem', color: '#64748B', marginTop: '0.25rem' }}>
                            📍 {halt.location_name} · ⏰ {halt.scheduled_arrival} - {halt.scheduled_departure}
                          </div>
                          {halt.notes && <div style={{ fontSize: '0.75rem', color: '#475569', marginTop: '0.25rem' }}>💡 {halt.notes}</div>}
                        </div>

                        {!halt.is_completed ? (
                          <button className="btn btn-sm" style={{ background: '#22C55E', color: 'white', fontWeight: 700 }} onClick={() => markHaltCompleted(halt)}>
                            ✓ Conclude Checkpoint
                          </button>
                        ) : (
                          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#16A34A' }}>Completed</span>
                        )}
                      </div>
                    ))}
                    {schedule.length === 0 && (
                      <div style={{ textAlign: 'center', padding: '2rem', color: '#9CA3AF' }}>No halts added yet. Click "+ Add Halt / Stop" above.</div>
                    )}
                  </div>
                </div>
              </div>

              {/* Right Column: Dindi Details & QR Exporter */}
              <div>
                <div className="card" style={{ marginBottom: '1.25rem' }}>
                  <h3 style={{ fontSize: '0.95rem', fontWeight: 800, marginBottom: '0.75rem' }}>🚩 Dindi Info</h3>
                  <div style={{ fontSize: '0.85rem', lineHeight: 1.8, color: '#334155' }}>
                    <div><strong>Code:</strong> {selectedDindi.code}</div>
                    <div><strong>Name:</strong> {selectedDindi.name}</div>
                    <div><strong>Leader:</strong> {selectedDindi.leader_name}</div>
                    <div><strong>Origin:</strong> {selectedDindi.origin}</div>
                    <div><strong>Enrolled Members:</strong> {selectedDindi.total_members}</div>
                  </div>
                </div>

                {/* QR Code Exporter Card */}
                <div className="card" style={{ textAlign: 'center', border: '2px dashed #7C3AED', background: '#FAF5FF' }}>
                  <h3 style={{ fontSize: '0.9rem', fontWeight: 800, color: '#7C3AED', marginBottom: '0.5rem' }}>📷 Dindi Official QR Code</h3>
                  <div style={{ background: 'white', padding: '1rem', borderRadius: 12, display: 'inline-block', margin: '0.5rem 0' }}>
                    <div style={{ fontSize: '3.5rem', lineHeight: 1 }}>📱</div>
                    <div style={{ fontSize: '0.7rem', fontFamily: 'monospace', color: '#64748B', marginTop: '0.25rem' }}>{selectedDindi.qr_code_data}</div>
                  </div>
                  <p style={{ fontSize: '0.75rem', color: '#64748B', marginBottom: '0.75rem' }}>Print or share this QR code for new pilgrims to scan and join instantly.</p>
                  <button className="btn btn-secondary btn-sm btn-full" onClick={() => window.print()}>
                    🖨️ Print / Download QR Badge
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Add Halt Modal */}
        {showAddHalt && (
          <div className="modal-overlay" onClick={() => setShowAddHalt(false)}>
            <div className="modal" onClick={e => e.stopPropagation()}>
              <h2 style={{ marginBottom: '1rem' }}>+ Add Itinerary Halt / Stop</h2>
              <div className="form-group">
                <label>Day Number</label>
                <input className="input" type="number" value={haltDay} onChange={e => setHaltDay(Number(e.target.value))} />
              </div>
              <div className="form-group">
                <label>Halt Type</label>
                <select className="input" value={haltType} onChange={e => setHaltType(e.target.value)}>
                  <option value="DEPARTURE">🌅 Departure</option>
                  <option value="BREAKFAST">🍵 Breakfast / Tea</option>
                  <option value="LUNCH">🍛 Lunch (Annachhatra)</option>
                  <option value="RINGAN">🎪 Ringan Ceremony</option>
                  <option value="TEMPLE">🛕 Temple Visit</option>
                  <option value="NIGHT_SHELTER">🏕️ Night Shelter</option>
                </select>
              </div>
              <div className="form-group">
                <label>Halt Title</label>
                <input className="input" placeholder="e.g. Afternoon Mahaprasad Lunch Halt" value={haltTitle} onChange={e => setHaltTitle(e.target.value)} />
              </div>
              <div className="form-group">
                <label>Location Name</label>
                <input className="input" placeholder="e.g. Akurdi Vitthal Temple Grounds" value={haltLocation} onChange={e => setHaltLocation(e.target.value)} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div className="form-group">
                  <label>Arrival Time (HH:MM)</label>
                  <input className="input" type="time" value={haltArr} onChange={e => setHaltArr(e.target.value)} />
                </div>
                <div className="form-group">
                  <label>Departure Time (HH:MM)</label>
                  <input className="input" type="time" value={haltDep} onChange={e => setHaltDep(e.target.value)} />
                </div>
              </div>
              <div className="form-group">
                <label>Notes / Instructions</label>
                <input className="input" placeholder="e.g. Free tea & poha distributed by Local Mandal" value={haltNotes} onChange={e => setHaltNotes(e.target.value)} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginTop: '1.5rem' }}>
                <button className="btn btn-secondary" onClick={() => setShowAddHalt(false)}>Cancel</button>
                <button className="btn btn-primary" onClick={handleAddHalt} disabled={submitting}>
                  {submitting ? 'Saving...' : '✓ Add Halt'}
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
