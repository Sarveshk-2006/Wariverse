'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { loginUser, setAuth } from '@/lib/api';
import { useLanguage, Language } from '@/context/LanguageContext';

const DEMO_ROLES = [
  { role: 'NGO', email: 'ngo@wariverse.demo', icon: '🌿', nameKey: 'ngo', color: '#7C3AED' },
  { role: 'ADMIN', email: 'admin@wariverse.demo', icon: '⚙️', nameKey: 'admin', color: '#4F46E5' },
];

const DEMO_PASSWORD = 'Demo@123';

export default function LoginPage() {
  const router = useRouter();
  const { lang, setLang, t } = useLanguage();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [activeRole, setActiveRole] = useState<string | null>(null);

  const handleLogin = async (e?: React.FormEvent, overrideEmail?: string, overridePassword?: string) => {
    if (e) e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const loginEmail = overrideEmail || email;
      const loginPassword = overridePassword || password;
      const data = await loginUser(loginEmail, loginPassword);
      setAuth(data.access_token, {
        id: data.user_id,
        role: data.role,
        display_name: data.display_name,
        email: loginEmail,
      });

      const roleRoutes: Record<string, string> = {
        NGO: '/dashboard/ngo',
        ADMIN: '/dashboard/admin',
      };
      const destRoute = roleRoutes[data.role];
      if (!destRoute) {
        throw new Error('Access restricted to Admins and NGOs only.');
      }
      router.push(destRoute);
    } catch (err: any) {
      setError(err.message || 'Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleDemoLogin = async (demoEmail: string) => {
    setActiveRole(demoEmail);
    setEmail(demoEmail);
    setPassword(DEMO_PASSWORD);
    await handleLogin(undefined, demoEmail, DEMO_PASSWORD);
    setActiveRole(null);
  };

  return (
    <div style={{ minHeight: '100vh', background: '#F8FAFC', display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '2rem 1.5rem' }}>
      <div style={{ width: '100%', maxWidth: '960px', margin: '0 auto' }}>
        
        <div className="content-grid" style={{ display: 'grid', gridTemplateColumns: '1.2fr 1.5fr', gap: '3rem', alignItems: 'center' }}>
          
          {/* Hero Image */}
          <div style={{ 
            borderRadius: '16px', 
            overflow: 'hidden',
            boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
            position: 'relative',
            background: '#FFFFFF',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            height: '100%',
            minHeight: '600px'
          }}>
            <img 
              src="/images/login-hero.jpg" 
              alt="Variverse AI" 
              style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
            />
          </div>

          {/* Right Side Forms */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', padding: '1rem 0' }}>
            
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: '0.5rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <div>
                  <h1 style={{ fontSize: '1.4rem', fontWeight: 800, color: '#0F172A', lineHeight: 1.1 }}>{t('appName')}</h1>
                  <div style={{ fontSize: '0.75rem', color: '#64748B', fontWeight: 500 }}>{t('appSubtitle')}</div>
                </div>
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
            
            {/* Sign In Form */}
            <div className="card" style={{ background: '#FFFFFF', border: '1px solid #E2E8F0', padding: '1.75rem', boxShadow: '0 4px 12px rgba(0,0,0,0.05)', borderRadius: '16px' }}>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0F172A', marginBottom: '0.25rem' }}>{t('signIn')}</h2>
              <p style={{ color: '#64748B', fontSize: '0.85rem', marginBottom: '1.25rem' }}>
                {t('signInDescription')}
              </p>

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
                      const selected = e.target.value;
                      if (selected === 'admin') setEmail('admin@wariverse.demo');
                      else if (selected === 'ngo') setEmail('ngo@wariverse.demo');
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
                    className="input"
                    type="email"
                    placeholder="name@wariverse.org"
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    required
                  />
                </div>
                <div className="form-group" style={{ marginBottom: '1.25rem' }}>
                  <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#334155' }}>{t('password')}</label>
                  <input
                    className="input"
                    type="password"
                    placeholder="••••••••"
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    required
                  />
                </div>
                <button
                  type="submit"
                  className="btn btn-primary btn-full"
                  style={{ padding: '0.75rem', fontSize: '0.925rem' }}
                  disabled={loading}
                >
                  {loading ? <><span className="spinner" style={{ width: 18, height: 18, borderWidth: 2, borderColor: 'rgba(255,255,255,0.3)', borderTopColor: 'white' }} /> {t('signIn')}...</> : `${t('signIn')} →`}
                </button>
              </form>

              <div style={{ marginTop: '1.25rem', paddingTop: '1rem', borderTop: '1px solid #F1F5F9', fontSize: '0.775rem', color: '#64748B', textAlign: 'center' }}>
                🔑 {t('defaultDemoPassword')}: <code style={{ background: '#F1F5F9', padding: '2px 6px', borderRadius: 4, color: '#0F172A', fontWeight: 700 }}>Demo@123</code>
              </div>
            </div>
            
          </div>
        </div>

        {/* Footer */}
        <div style={{ textAlign: 'center', marginTop: '2.5rem', color: '#64748B', fontSize: '0.775rem' }}>
          <p style={{ fontWeight: 600 }}>Made with ❤️ by Team Terminal X</p>
        </div>

      </div>
    </div>
  );
}
