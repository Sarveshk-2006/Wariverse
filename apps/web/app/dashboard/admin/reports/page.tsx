'use client';
import { useState, useEffect } from 'react';
import { apiCall } from '@/lib/api';
import Sidebar from '@/components/Sidebar';
import { useLanguage } from '@/context/LanguageContext';

export default function ReportsDashboard() {
  const { t } = useLanguage();
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchReports = async () => {
    setLoading(true);
    try {
      const data = await apiCall('/reports');
      setReports(data || []);
    } catch (e) {
      console.error(e);
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchReports();
  }, []);

  const changePriority = async (id: string, newPriority: string) => {
    setReports(prev => prev.map(f => f.id === id ? { ...f, priority: newPriority } : f));
    try {
      await apiCall(`/reports/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({ priority: newPriority })
      });
    } catch(e) {
      console.error("Failed to update priority on backend", e);
    }
  };

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 800 }}>📝 {t('reports') || 'Reports'}</h1>
            <p style={{ fontSize: '0.8rem', color: '#6B7280' }}>Pilgrim reports straight from the app.</p>
          </div>
          <button className="btn btn-secondary btn-sm" onClick={fetchReports} disabled={loading}>
            {loading ? '⏳' : '🔄 Refresh'}
          </button>
        </header>

        <div className="dashboard-content">
          {loading && reports.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '3rem' }}>
              <div className="spinner" style={{ width: 48, height: 48, margin: 'auto' }} />
            </div>
          ) : (
            <div className="card">
              <h3 style={{ marginBottom: '1rem' }}>Actionable Reports</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {reports.length === 0 ? (
                  <div style={{ padding: '2rem', textAlign: 'center', color: '#9CA3AF' }}>No reports found.</div>
                ) : reports.map(f => (
                  <div key={f.id} style={{ display: 'flex', gap: '1rem', padding: '1rem', border: '1px solid #E2E8F0', borderRadius: 8, background: '#F8FAFC' }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 700, fontSize: '0.9rem', marginBottom: '0.25rem' }}>{f.user || 'Unknown Varkari'}</div>
                      <div style={{ fontSize: '0.8rem', color: '#475569', marginBottom: '0.5rem' }}>{f.message}</div>
                      <div style={{ fontSize: '0.7rem', color: '#94A3B8' }}>{new Date(f.timestamp).toLocaleString()}</div>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '0.5rem' }}>
                      <select 
                        value={f.priority || 'LOW'} 
                        onChange={(e) => changePriority(f.id, e.target.value)}
                        style={{ 
                          padding: '0.25rem 0.5rem', borderRadius: 6, fontSize: '0.75rem', fontWeight: 600, 
                          border: '1px solid #CBD5E1', background: 'white', cursor: 'pointer',
                          color: f.priority === 'HIGH' ? '#EF4444' : f.priority === 'MEDIUM' ? '#F59E0B' : '#10B981'
                        }}
                      >
                        <option value="LOW">Low Priority</option>
                        <option value="MEDIUM">Medium Priority</option>
                        <option value="HIGH">High Priority</option>
                      </select>
                      <span className={`badge ${f.status === 'RESOLVED' ? 'badge-green' : 'badge-orange'}`}>
                        {f.status || 'PENDING'}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
