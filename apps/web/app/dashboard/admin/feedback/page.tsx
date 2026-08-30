'use client';
import { useState, useEffect } from 'react';
import { apiCall } from '@/lib/api';
import Sidebar from '@/components/Sidebar';
import { useLanguage } from '@/context/LanguageContext';

export default function FeedbackDashboard() {
  const { t } = useLanguage();
  const [feedbacks, setFeedbacks] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchFeedbacks = async () => {
    setLoading(true);
    try {
      const data = await apiCall('/feedback');
      setFeedbacks(data || []);
    } catch (e) {
      console.error(e);
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchFeedbacks();
  }, []);


  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 800 }}>📝 {t('feedback') || 'Feedback'}</h1>
            <p style={{ fontSize: '0.8rem', color: '#6B7280' }}>Pilgrim feedback and suggestions.</p>
          </div>
          <button className="btn btn-secondary btn-sm" onClick={fetchFeedbacks} disabled={loading}>
            {loading ? '⏳' : '🔄 Refresh'}
          </button>
        </header>

        <div className="dashboard-content">
          {loading && feedbacks.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '3rem' }}>
              <div className="spinner" style={{ width: 48, height: 48, margin: 'auto' }} />
            </div>
          ) : (
            <div className="card">
              <h3 style={{ marginBottom: '1rem' }}>User Feedback</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {feedbacks.length === 0 ? (
                  <div style={{ padding: '2rem', textAlign: 'center', color: '#9CA3AF' }}>No reports found.</div>
                ) : feedbacks.map(f => (
                  <div key={f.id} style={{ display: 'flex', gap: '1rem', padding: '1rem', border: '1px solid #E2E8F0', borderRadius: 8, background: '#F8FAFC' }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 700, fontSize: '0.9rem', marginBottom: '0.25rem' }}>{f.user || 'Unknown Varkari'}</div>
                      <div style={{ fontSize: '0.8rem', color: '#475569', marginBottom: '0.5rem' }}>{f.message}</div>
                      <div style={{ fontSize: '0.7rem', color: '#94A3B8' }}>{new Date(f.timestamp).toLocaleString()}</div>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '0.5rem' }}>
                      
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
