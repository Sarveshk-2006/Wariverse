'use client';
import { useState, useEffect } from 'react';
import { apiCall } from '@/lib/api';
import Sidebar from '@/components/Sidebar';
import { useLanguage } from '@/context/LanguageContext';

export default function AdminToiletsPage() {
  const { t, tn } = useLanguage();
  const [toilets, setToilets] = useState<any[]>([]);
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('ALL');

  useEffect(() => {
    Promise.all([apiCall('/toilets'), apiCall('/sanitation_reports')]).then(([tData, rData]) => { setToilets(tData); setReports(rData || []); setLoading(false); });
  }, []);

  
  
  const getIssueLabel = (issue: string) => {
    if (!issue) return 'NEEDS CLEANING';
    const dict: any = {
      'NO_WATER': t('noWater') || 'NO WATER',
      'NEEDS_CLEANING': t('needsCleaning') || 'NEEDS CLEANING',
      'OVERFLOW': t('overflow') || 'OVERFLOW',
      'DAMAGED': t('damaged') || 'DAMAGED',
      'OTHER': t('other') || 'OTHER'
    };
    return dict[issue] || issue.replace('_', ' ');
  };


  const getStatusLabel = (status: string) => {
    const dict: any = {
      'REPORTED': t('statusReported') || 'REPORTED',
      'ASSIGNED': t('statusAssigned') || 'ASSIGNED',
      'IN_PROGRESS': t('statusInProgress') || 'IN PROGRESS',
      'RESOLVED': t('statusResolved') || 'RESOLVED'
    };
    return dict[status] || status;
  };

  const updateReportStatus = async (id: string, status: string) => {
    await apiCall(`/sanitation_reports/${id}`, { method: 'PATCH', body: JSON.stringify({ status }) });
    setReports(prev => prev.map(r => r.id === id ? { ...r, status } : r));
  };

  const statusColor: Record<string, string> = {
    CLEAN: '#22C55E', NEEDS_CLEANING: '#F59E0B', MAINTENANCE: '#EF4444', CLOSED: '#9CA3AF',
  };

  const filtered = filter === 'ALL' ? toilets : toilets.filter(t => t.status === filter);
  const needCleaning = toilets.filter(t => t.status === 'NEEDS_CLEANING').length;
  const clean = toilets.filter(t => t.status === 'CLEAN').length;
  const maintenance = toilets.filter(t => t.status === 'MAINTENANCE').length;

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 800 }}>🚻 {t('toilets') || 'Toilet Overview'}</h1>
            <p style={{ fontSize: '0.8rem', color: '#6B7280' }}>All toilet blocks across the route</p>
          </div>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <span className="badge badge-yellow">{needCleaning} Need Cleaning</span>
            <span className="badge badge-green">{clean} Clean</span>
          </div>
        </header>

        <div className="dashboard-content">
          <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(4, 1fr)', marginBottom: '1.5rem' }}>
            {[
              { label: 'Need Cleaning', value: needCleaning, color: '#F59E0B', icon: '🧹' },
              { label: 'Clean', value: clean, color: '#22C55E', icon: '✅' },
              { label: 'Maintenance', value: maintenance, color: '#EF4444', icon: '🔧' },
              { label: 'Total Units', value: toilets.reduce((a, t) => a + (t.total_units || 0), 0), color: '#6366F1', icon: '🚻' },
            ].map(s => (
              <div key={s.label} className="stat-card" style={{ borderTop: `3px solid ${s.color}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <div><div className="stat-value" style={{ color: s.color }}>{s.value}</div><div className="stat-label">{s.label}</div></div>
                  <span style={{ fontSize: '1.75rem' }}>{s.icon}</span>
                </div>
              </div>
            ))}
          </div>

          {/* Filter */}
          <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
            {['ALL', 'NEEDS_CLEANING', 'CLEAN', 'MAINTENANCE', 'CLOSED'].map(f => (
              <button key={f} className={`btn btn-sm ${filter === f ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => setFilter(f)}>
                {f.replace('_', ' ')} {f !== 'ALL' && `(${toilets.filter(t => t.status === f).length})`}
              </button>
            ))}
          </div>

          {loading ? (
            <div style={{ textAlign: 'center', padding: '3rem' }}><div className="spinner" style={{ width: 40, height: 40, margin: 'auto' }} /></div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1rem' }}>
              {[...filtered].sort((a, b) => {
                const ord = { NEEDS_CLEANING: 0, MAINTENANCE: 1, CLEAN: 2, CLOSED: 3 };
                return (ord[a.status as keyof typeof ord] || 2) - (ord[b.status as keyof typeof ord] || 2);
              }).map((t: any) => (
                <div key={t.id} className="card" style={{ borderLeft: `4px solid ${statusColor[t.status] || '#9CA3AF'}` }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.75rem' }}>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>{t.name}</div>
                      <div style={{ fontSize: '0.75rem', color: '#6B7280' }}>{t.total_units} units · {t.gender}</div>
                    </div>
                    <span className="badge" style={{ background: `${statusColor[t.status]}20`, color: statusColor[t.status] }}>{t.status}</span>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem', fontSize: '0.8rem', color: '#6B7280' }}>
                    <div>⭐ Rating: <strong>{t.rating}</strong></div>
                    <div>🕐 {t.minutes_since_cleaned !== null ? `${t.minutes_since_cleaned} min ago` : 'Unknown'}</div>
                    <div>📱 QR: {t.qr_code}</div>
                    <div style={{ color: t.status === 'NEEDS_CLEANING' ? '#EF4444' : '#22C55E' }}>
                      {t.status === 'NEEDS_CLEANING' ? '⚠️ Needs attention' : t.status === 'CLEAN' ? '✅ Clean' : '🔧 Under maintenance'}
                    </div>
                  </div>
                </div>
              ))}
              {filtered.length === 0 && <div style={{ textAlign: 'center', padding: '3rem', color: '#9CA3AF', gridColumn: '1/-1' }}>No toilets found</div>}
            </div>
          )}
        </div>

        <div className="card" style={{ marginTop: '2rem' }}>
          <h3>🧹 {t('sanitationReportsTitle') || 'Sanitation Reports (CleanWari)'}</h3>
          {reports.length === 0 ? (
            <p style={{ color: '#6B7280', marginTop: '1rem' }}>{t('noSanitationIncidents') || 'No recent sanitation incidents reported.'}</p>
          ) : (
            <div style={{ display: 'grid', gap: '0.75rem', marginTop: '1rem' }}>
              {reports.map(r => (
                <div key={r.id} className="list-item" style={{ borderLeft: `4px solid ${r.status === 'RESOLVED' ? '#22C55E' : '#F59E0B'}` }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 800 }}>{r.issueType?.replace('_', ' ') || 'NEEDS CLEANING'}</div>
                    <div style={{ fontSize: '0.85rem', color: '#6B7280' }}>{t('locationPrefix') || 'Location:'} {r.toiletName || t('unknownBlock') || 'Unknown Block'}</div>
                    <div style={{ fontSize: '0.85rem', color: '#6B7280' }}>{t('notesPrefix') || 'Notes:'} {r.description || t('noDetails') || 'No additional details'}</div>
                  </div>
                  <div>
                    <span className={`badge ${r.status === 'RESOLVED' ? 'badge-green' : 'badge-yellow'}`}>{getStatusLabel(r.status)}</span>
                  </div>
                  {r.status !== 'RESOLVED' && (
                    <button className="btn btn-sm btn-primary" style={{ marginLeft: '1rem' }} onClick={() => updateReportStatus(r.id, 'RESOLVED')}>
                      {t('resolve') || 'Mark Resolved'}
                    </button>
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
