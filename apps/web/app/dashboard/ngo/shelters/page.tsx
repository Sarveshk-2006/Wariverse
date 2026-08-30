'use client';
import { useState, useEffect } from 'react';
import { apiCall } from '@/lib/api';
import Sidebar from '@/components/Sidebar';
import { useLanguage } from '@/context/LanguageContext';

export default function NGOSheltersPage() {
  const { t, tn } = useLanguage();
  const [shelters, setShelters] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { apiCall('/shelters').then(d => { setShelters(d); setLoading(false); }); }, []);

  const totalCap = shelters.reduce((a, s) => a + s.capacity, 0);
  const totalOcc = shelters.reduce((a, s) => a + s.current_occupancy, 0);

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 800 }}>🏠 {t('sheltersDistribution')}</h1>
            <p style={{ fontSize: '0.8rem', color: '#6B7280' }}>{t('sheltersSub')}</p>
          </div>
          <span className="badge badge-blue">{tn(totalOcc.toLocaleString())}/{tn(totalCap.toLocaleString())} {t('occupied')}</span>
        </header>
        <div className="dashboard-content">
          <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)', marginBottom: '1.5rem' }}>
            {[
              { labelKey: 'totalCapacity', value: totalCap.toLocaleString(), color: '#6366F1', icon: '🏠' },
              { labelKey: 'occupied', value: totalOcc.toLocaleString(), color: '#F97316', icon: '👥' },
              { labelKey: 'spacesAvailable', value: (totalCap - totalOcc).toLocaleString(), color: '#22C55E', icon: '✅' },
              { labelKey: 'fullStatus', value: shelters.filter(s => s.current_occupancy >= s.capacity).length, color: '#EF4444', icon: '🔴' },
            ].map(s => (
              <div key={s.labelKey} className="stat-card" style={{ borderTop: `3px solid ${s.color}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <div><div className="stat-value" style={{ color: s.color }}>{tn(s.value)}</div><div className="stat-label">{t(s.labelKey)}</div></div>
                  <span style={{ fontSize: '1.75rem' }}>{s.icon}</span>
                </div>
              </div>
            ))}
          </div>
          {loading ? <div style={{ textAlign: 'center', padding: '3rem' }}><div className="spinner" style={{ width: 40, height: 40, margin: 'auto' }} /></div> : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1rem' }}>
              {shelters.map((s: any) => {
                const pct = s.capacity > 0 ? (s.current_occupancy / s.capacity) * 100 : 0;
                const isFull = s.current_occupancy >= s.capacity;
                return (
                  <div key={s.id} className="card" style={{ borderTop: `3px solid ${isFull ? '#EF4444' : pct > 80 ? '#F97316' : '#22C55E'}` }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.75rem' }}>
                      <div><div style={{ fontWeight: 700, fontSize: '0.95rem' }}>{t(s.name)}</div><div style={{ fontSize: '0.75rem', color: '#6B7280' }}>{s.shelter_type || 'Shelter'}</div></div>
                      <span className={`badge ${isFull ? 'badge-red' : 'badge-green'}`}>{isFull ? t('fullStatus') : `${tn(s.capacity - s.current_occupancy)} ${t('spacesAvailable')}`}</span>
                    </div>
                    <div className="progress-bar" style={{ marginBottom: '0.5rem' }}>
                      <div className="progress-fill" style={{ width: `${pct}%`, background: pct > 80 ? '#EF4444' : '#22C55E' }} />
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', color: '#6B7280', marginBottom: '0.5rem' }}>
                      <span>{tn(s.current_occupancy)}/{tn(s.capacity)} {t('occupied')} ({tn(pct.toFixed(0))}%)</span>
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.375rem', fontSize: '0.75rem', color: '#6B7280' }}>
                      <div>{s.has_meals ? '🍛' : '🚫'}</div>
                      <div>{s.has_toilets ? '🚻' : '🚫'}</div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
