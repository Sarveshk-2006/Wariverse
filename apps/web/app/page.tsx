'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { setAuth } from '@/lib/api';
import { useLanguage, Language } from '@/context/LanguageContext';

// ── Static credentials — looks dynamic with animated flow ─────────────────────
const STATIC_USERS: Record<string, { password: string; role: string; display_name: string; user_id: string }> = {
  'admin@wariverse.demo': {
    password: 'Demo@123',
    role: 'ADMIN',
    display_name: 'Vari Control Admin',
    user_id: 'admin-001',
  },
  'ngo@wariverse.demo': {
    password: 'Demo@123',
    role: 'NGO',
    display_name: 'Seva Trust Coordinator',
    user_id: 'ngo-001',
  },
};

const ROLE_ROUTES: Record<string, string> = {
  ADMIN: '/dashboard/admin',
  NGO: '/dashboard/ngo',
};

// Fake stages shown during "authentication" — makes it look live
const AUTH_STAGES = [
  'Connecting to secure gateway...',
  'Verifying identity...',
  'Checking role permissions...',
  'Loading dashboard...',
];

const DEMO_ROLES = [
  { role: 'NGO',   email: 'ngo@wariverse.demo',   icon: '🌿', color: '#7C3AED' },
  { role: 'ADMIN', email: 'admin@wariverse.demo',  icon: '⚙️', color: '#4F46E5' },
];

const DEMO_PASSWORD = 'Demo@123';

export default function LoginPage() {
  const router = useRouter();
  const { lang, setLang, t } = useLanguage();
  const [email, setEmail]     = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [stage, setStage]     = useState('');
  const [error, setError]     = useState('');
  const [activeRole, setActiveRole] = useState<string | null>(null);

  // Simulated async auth with animated stages
  const simulateAuth = async (loginEmail: string, loginPassword: string) => {
    setLoading(true);
    setError('');
    setStage('');

    const user = STATIC_USERS[loginEmail.toLowerCase().trim()];

    // Stage 1
    setStage(AUTH_STAGES[0]);
    await delay(420);

    // Stage 2 — check credentials
    setStage(AUTH_STAGES[1]);
    await delay(480);

    if (!user || user.password !== loginPassword) {
      setLoading(false);
      setStage('');
      setError('Invalid credentials. Please check your email and password.');
      return;
    }

    // Stage 3
    setStage(AUTH_STAGES[2]);
    await delay(360);

    if (!ROLE_ROUTES[user.role]) {
      setLoading(false);
      setStage('');
      setError('Access restricted to Admins and NGOs only.');
      return;
    }

    // Stage 4
    setStage(AUTH_STAGES[3]);
    await delay(300);

    // Set auth state with a fake JWT-like token
    setAuth(`demo.${btoa(loginEmail)}.${Date.now()}`, {
      id: user.user_id,
      role: user.role,
      display_name: user.display_name,
      email: loginEmail,
    });

    router.push(ROLE_ROUTES[user.role]);
  };

  const handleLogin = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    await simulateAuth(email, password);
  };

  const handleDemoLogin = async (demoEmail: string) => {
    setActiveRole(demoEmail);
    setEmail(demoEmail);
    setPassword(DEMO_PASSWORD);
    await simulateAuth(demoEmail, DEMO_PASSWORD);
    setActiveRole(null);
  };

  return (
    <div style={{ minHeight: '100vh', background: '#F8FAFC', display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '2rem 1.5rem' }}>
      <div style={{ width: '100%', maxWidth: '960px', margin: '0 auto' }}>

        <div className="content-grid" style={{ display: 'grid', gridTemplateColumns: '1.2fr 1.5fr', gap: '3rem', alignItems: 'center' }}>

          {/* Hero Image */}
          <div style={{
            borderRadius: '16px', overflow: 'hidden',
            boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
            background: '#FFFFFF', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            height: '100%', minHeight: '600px',
          }}>
            <img src="/images/login-hero.jpg" alt="Variverse" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          </div>

          {/* Right — Form */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', padding: '1rem 0' }}>

            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: '0.5rem' }}>
              <div>
                <h1 style={{ fontSize: '1.4rem', fontWeight: 800, color: '#0F172A', lineHeight: 1.1 }}>{t('appName')}</h1>
                <div style={{ fontSize: '0.75rem', color: '#64748B', fontWeight: 500 }}>{t('appSubtitle')}</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: '#FFFFFF', padding: '0.4rem 0.8rem', borderRadius: 8, border: '1px solid #E2E8F0', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
                <span style={{ fontSize: '0.8rem', fontWeight: 600, color: '#64748B' }}>🌐</span>
                <select
                  value={lang}
                  onChange={(e) => setLang(e.target.value as Language)}
                  style={{ border: 'none', background: 'transparent', fontSize: '0.8rem', fontWeight: 700, color: '#0F172A', cursor: 'pointer', outline: 'none' }}
                >
                  <option value="mr">मराठी</option>
                  <option value="hi">हिंदी</option>
                  <option value="en">English</option>
                </select>
              </div>
            </div>

            {/* Quick Role Buttons */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
              {DEMO_ROLES.map(r => (
                <button
                  key={r.role}
                  onClick={() => handleDemoLogin(r.email)}
                  disabled={loading}
                  style={{
                    display: 'flex', alignItems: 'center', gap: '0.6rem',
                    padding: '0.7rem 1rem', borderRadius: 10,
                    border: `2px solid ${activeRole === r.email ? r.color : '#E2E8F0'}`,
                    background: activeRole === r.email ? `${r.color}10` : '#FFFFFF',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    fontWeight: 700, fontSize: '0.85rem', color: r.color,
                    transition: 'all 0.2s',
                  }}
                >
                  <span style={{ fontSize: '1.2rem' }}>{r.icon}</span>
                  <div style={{ textAlign: 'left' }}>
                    <div>{r.role}</div>
                    <div style={{ fontSize: '0.65rem', color: '#94A3B8', fontWeight: 400 }}>Quick login</div>
                  </div>
                </button>
              ))}
            </div>

            {/* Sign In Card */}
            <div className="card" style={{ background: '#FFFFFF', border: '1px solid #E2E8F0', padding: '1.75rem', boxShadow: '0 4px 12px rgba(0,0,0,0.05)', borderRadius: '16px' }}>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0F172A', marginBottom: '0.25rem' }}>{t('signIn')}</h2>
              <p style={{ color: '#64748B', fontSize: '0.85rem', marginBottom: '1.25rem' }}>
                {t('signInDescription')}
              </p>

              {/* Auth stage indicator */}
              {loading && stage && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', background: '#EFF6FF', border: '1px solid #BFDBFE', borderRadius: 8, padding: '0.6rem 0.875rem', marginBottom: '1rem', fontSize: '0.8rem', color: '#1E40AF', fontWeight: 600 }}>
                  <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2, borderColor: '#BFDBFE', borderTopColor: '#3B82F6', flexShrink: 0 }} />
                  {stage}
                </div>
              )}

              {error && (
                <div style={{ background: '#FEE2E2', border: '1px solid #FCA5A5', color: '#991B1B', padding: '0.65rem 0.875rem', borderRadius: 8, marginBottom: '1.15rem', fontSize: '0.825rem', fontWeight: 600 }}>
                  ⚠️ {error}
                </div>
              )}

              <form onSubmit={handleLogin}>
                <div className="form-group" style={{ marginBottom: '1rem' }}>
                  <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#334155' }}>Select Role</label>
                  <select
                    className="input"
                    onChange={(e) => {
                      const v = e.target.value;
                      if (v === 'admin') setEmail('admin@wariverse.demo');
                      else if (v === 'ngo') setEmail('ngo@wariverse.demo');
                      else setEmail('');
                    }}
                    style={{ width: '100%' }}
                  >
                    <option value="">-- {t('signIn')} --</option>
                    <option value="ngo">{t('ngo')}</option>
                    <option value="admin">{t('admin')}</option>
                  </select>
                </div>

                <div className="form-group" style={{ marginBottom: '1rem' }}>
                  <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#334155' }}>{t('emailAddress')}</label>
                  <input
                    className="input" type="email"
                    placeholder="name@wariverse.org"
                    value={email} onChange={e => setEmail(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group" style={{ marginBottom: '1.25rem' }}>
                  <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#334155' }}>{t('password')}</label>
                  <input
                    className="input" type="password"
                    placeholder="••••••••"
                    value={password} onChange={e => setPassword(e.target.value)}
                    required
                  />
                </div>

                <button
                  type="submit"
                  className="btn btn-primary btn-full"
                  style={{ padding: '0.75rem', fontSize: '0.925rem' }}
                  disabled={loading}
                >
                  {loading
                    ? <><span className="spinner" style={{ width: 18, height: 18, borderWidth: 2, borderColor: 'rgba(255,255,255,0.3)', borderTopColor: 'white' }} /> {t('signIn')}...</>
                    : `${t('signIn')} →`}
                </button>
              </form>

              <div style={{ marginTop: '1.25rem', paddingTop: '1rem', borderTop: '1px solid #F1F5F9', fontSize: '0.775rem', color: '#64748B', textAlign: 'center' }}>
                🔑 {t('defaultDemoPassword')}: <code style={{ background: '#F1F5F9', padding: '2px 6px', borderRadius: 4, color: '#0F172A', fontWeight: 700 }}>Demo@123</code>
              </div>
            </div>

          </div>
        </div>

        <div style={{ textAlign: 'center', marginTop: '2.5rem', color: '#64748B', fontSize: '0.775rem' }}>
          <p style={{ fontWeight: 600 }}>Made with ❤️ by Team Terminal X</p>
        </div>

      </div>
    </div>
  );
}

function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
