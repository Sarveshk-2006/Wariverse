'use client';
import { useState, useEffect } from 'react';
import { apiCall } from '@/lib/api';
import Sidebar from '@/components/Sidebar';
import { useLanguage } from '@/context/LanguageContext';

export default function NGOWaterPage() {
  const { t, tn } = useLanguage();
  const [water, setWater] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('ALL');

  useEffect(() => { apiCall('/water').then(d => { setWater(d); setLoading(false); }); }, []);

  const statusColor: Record<string, string> = { AVAILABLE: '#22C55E', LOW: '#F59E0B', EMPTY: '#EF4444', MAINTENANCE: '#9CA3AF' };
  const filtered = filter === 'ALL' ? water : water.filter(w => w.status === filter);

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 800 }}>💧 {t('waterDistribution')}</h1>
            <p style={{ fontSize: '0.8rem', color: '#6B7280' }}>{t('waterSub')}</p>
          </div>
          <span className="badge badge-blue">{tn(water.filter(w => w.status === 'AVAILABLE').length)}/{tn(water.length)} {t('available')}</span>
        </header>
        <div className="dashboard-content">
          <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)', marginBottom: '1.5rem' }}>
            {[
              { labelKey: 'available', value: water.filter(w => w.status === 'AVAILABLE').length, color: '#22C55E', icon: '💧' },
              { labelKey: 'Low Supply', value: water.filter(w => w.status === 'LOW').length, color: '#F59E0B', icon: '⚠️' },
              { labelKey: 'Empty', value: water.filter(w => w.status === 'EMPTY').length, color: '#EF4444', icon: '🔴' },
              { labelKey: 'filtered', value: water.filter(w => w.is_filtered || w.water_type === 'filtered').length, color: '#3B82F6', icon: '🔬' },
            ].map(s => (
              <div key={s.labelKey} className="stat-card" style={{ borderTop: `3px solid ${s.color}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <div><div className="stat-value" style={{ color: s.color }}>{tn(s.value)}</div><div className="stat-label">{t(s.labelKey)}</div></div>
                  <span style={{ fontSize: '1.75rem' }}>{s.icon}</span>
                </div>
              </div>
            ))}
          </div>
          <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
            {['ALL', 'AVAILABLE', 'LOW', 'EMPTY'].map(f => (
              <button key={f} className={`btn btn-sm ${filter === f ? 'btn-primary' : 'btn-secondary'}`} onClick={() => setFilter(f)}>
                {f} {f !== 'ALL' && `(${tn(water.filter(w => w.status === f).length)})`}
              </button>
            ))}
          </div>
          {loading ? <div style={{ textAlign: 'center', padding: '3rem' }}><div className="spinner" style={{ width: 40, height: 40, margin: 'auto' }} /></div> : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem' }}>
              {[...filtered].sort((a, b) => { const o: any = { EMPTY: 0, LOW: 1, AVAILABLE: 2, MAINTENANCE: 3 }; return (o[a.status] || 0) - (o[b.status] || 0); })
                .map((wp: any) => (
                  <div key={wp.id} className="card" style={{ borderLeft: `4px solid ${statusColor[wp.status || 'AVAILABLE']}` }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.75rem' }}>
                      <div><div style={{ fontWeight: 700 }}>{t(wp.name)}</div><div style={{ fontSize: '0.75rem', color: '#6B7280' }}>{t(wp.water_type || 'drinking')}</div></div>
                      <span className="badge" style={{ background: `${statusColor[wp.status || 'AVAILABLE']}20`, color: statusColor[wp.status || 'AVAILABLE'] }}>{wp.status}</span>
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.375rem', fontSize: '0.8rem', color: '#6B7280' }}>
                      <div>{wp.is_filtered || wp.water_type === 'filtered' ? '🔬 ' + t('filtered') : '💧 ' + t('drinking')}</div>
                      <div>{wp.capacity_liters ? `${tn(wp.capacity_liters)} L` : ''}</div>
                    </div>
                    {wp.status === 'EMPTY' && (
                      <div style={{ marginTop: '0.5rem', background: '#FEE2E2', borderRadius: 8, padding: '0.375rem 0.75rem', fontSize: '0.8rem', color: '#DC2626', fontWeight: 700 }}>
                        🔴 {t('refillRequired')}
                      </div>
                    )}
                  </div>
                ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
