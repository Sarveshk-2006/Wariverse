'use client';
import { useState, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { clearAuth, getUser } from '@/lib/api';
import { useLanguage, Language } from '@/context/LanguageContext';

type NavItemKey = { icon: string; key: string; path: string };

const ROLE_NAV: Record<string, NavItemKey[]> = {
  NGO: [
    { icon: '🏠', key: 'dashboard', path: '/dashboard/ngo' },
    { icon: '🍛', key: 'foodDist', path: '/dashboard/ngo/food' },
    { icon: '💧', key: 'waterDist', path: '/dashboard/ngo/water' },
    { icon: '🏠', key: 'shelter', path: '/dashboard/ngo/shelters' },
    { icon: '🤝', key: 'volunteers', path: '/dashboard/ngo/volunteers' },
  ],
  ADMIN: [
    { icon: '🏠', key: 'commandCenter', path: '/dashboard/admin' },
    { icon: '🗺️', key: 'digitalTwin', path: '/dashboard/admin/digital-twin' },
    { icon: '🆘', key: 'sosIncidents', path: '/dashboard/admin/sos' },
    { icon: '📊', key: 'analytics', path: '/dashboard/admin/analytics' },
    { icon: '🤖', key: 'aiPredictions', path: '/dashboard/admin/predictions' },
    { icon: '👥', key: 'users', path: '/dashboard/admin/users' },
    { icon: '🚨', key: 'reports', path: '/dashboard/admin/reports' },
    { icon: '💬', key: 'feedback', path: '/dashboard/admin/feedback' },
    { icon: '🍛', key: 'food', path: '/dashboard/admin/food' },
    { icon: '💧', key: 'water', path: '/dashboard/admin/water' },
    { icon: '🚻', key: 'toilets', path: '/dashboard/admin/toilets' },
    { icon: '👤', key: 'lostPersons', path: '/dashboard/admin/lost' },
    { icon: '🎮', key: 'demoControl', path: '/dashboard/admin/demo' },
    { icon: '📢', key: 'community', path: '/dashboard/admin/community' },
  ],
};

const ROLE_COLORS: Record<string, string> = {
  NGO: '#7C3AED',
  ADMIN: '#4F46E5',
};



export default function Sidebar() {
  const router = useRouter();
  const pathname = usePathname();
  const { lang, setLang, t } = useLanguage();
  const [user, setUser] = useState<any>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setUser(getUser());
    setMounted(true);
  }, []);

  const role = (mounted ? user?.role : 'ADMIN') || 'ADMIN';
  const displayName = mounted ? (user?.display_name || 'User') : 'User';
  const navItems = ROLE_NAV[role] || ROLE_NAV.ADMIN;
  const roleColor = ROLE_COLORS[role] || '#4F46E5';

  const roleKeyMap: Record<string, string> = {
    NGO: 'ngo',
    ADMIN: 'admin',
  };

  const handleLogout = () => {
    clearAuth();
    router.push('/');
  };

  return (
    <aside className="sidebar">
      {/* Devotional / Professional Header */}
      <div className="sidebar-logo">
        <img src="/images/logo.jpg" alt="VariVerse Logo" style={{ width: 44, height: 44, borderRadius: 12, objectFit: 'cover', flexShrink: 0, boxShadow: '0 2px 5px rgba(0,0,0,0.1)' }} />
        <div>
          <div className="sidebar-logo-text">{t('appName')}</div>
        </div>
      </div>

      {/* Language Switcher Dropdown */}
      <div style={{ padding: '0.625rem 1rem', background: '#F8FAFC', borderBottom: '1px solid #E2E8F0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#64748B' }}>🌐 {t('language')}:</span>
        <select
          value={lang}
          onChange={(e) => setLang(e.target.value as Language)}
          style={{ padding: '0.25rem 0.5rem', borderRadius: 6, border: '1px solid #CBD5E1', fontSize: '0.75rem', fontWeight: 600, background: 'white', cursor: 'pointer' }}
        >
          <option value="mr">मराठी</option>
          <option value="hi">हिंदी</option>
          <option value="en">English</option>
        </select>
      </div>

      {/* User Info */}
      <div style={{ padding: '0.75rem 1rem', background: `${roleColor}0D`, borderBottom: '1px solid #E2E8F0', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
        <div>
          <div style={{ fontSize: '0.85rem', fontWeight: 700, lineHeight: 1.2, color: '#1E293B' }}>{displayName}</div>
          <div style={{ fontSize: '0.7rem', color: roleColor, fontWeight: 600 }}>{t(roleKeyMap[role] || 'varkari')}</div>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="sidebar-nav">
        {navItems.map((item) => {
          const isActive = pathname === item.path;
          return (
            <button
              key={item.path}
              className={`nav-item ${isActive ? 'active' : ''}`}
              onClick={() => router.push(item.path)}
              style={{
                borderColor: isActive ? roleColor : 'transparent',
                color: isActive ? roleColor : '#475569',
              }}
            >
              <span className="nav-item-icon">{item.icon}</span>
              <span style={{ fontWeight: isActive ? 700 : 500 }}>{t(item.key)}</span>
            </button>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="sidebar-footer">
        <div style={{ fontSize: '0.75rem', color: '#D97706', fontWeight: 700, marginBottom: '0.5rem', textAlign: 'center' }}>
          {t('devotionalGreeting')}
        </div>
        <button className="btn btn-ghost btn-full btn-sm" onClick={handleLogout} style={{ border: '1px solid #E2E8F0' }}>
          🚪 {t('signOut')}
        </button>
      </div>
    </aside>
  );
}
