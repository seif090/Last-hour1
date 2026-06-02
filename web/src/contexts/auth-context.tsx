'use client';

import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { setTokens, clearTokens, loadTokens, setOnAuthError, api } from '@/lib/api';
import type { User } from '@/lib/types';

interface AuthContextValue {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, role?: string, referralCode?: string) => Promise<void>;
  logout: () => void;
  refresh: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    try {
      loadTokens();
      const token = localStorage.getItem('accessToken');
      if (!token) { setLoading(false); return; }
      setTokens(token, localStorage.getItem('refreshToken') || '');
      const data = await api<{ user: User }>('/auth/profile');
      setUser(data.user);
    } catch {
      clearTokens();
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    setOnAuthError(() => { setUser(null); clearTokens(); });
    (async () => {
      loadTokens();
      const token = localStorage.getItem('accessToken');
      if (!token) return;
      setTokens(token, localStorage.getItem('refreshToken') || '');
      try {
        const data = await api<{ user: User }>('/auth/profile');
        setUser(data.user);
      } catch {
        clearTokens();
        setUser(null);
      }
    })().finally(() => setLoading(false));
  }, []);

  const login = async (email: string, password: string) => {
    const res = await api<{ accessToken: string; refreshToken: string; user: User }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    setTokens(res.accessToken, res.refreshToken);
    setUser(res.user);
  };

  const register = async (email: string, password: string, role?: string, referralCode?: string) => {
    const res = await api<{ accessToken: string; refreshToken: string; user: User }>('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email, password, role, referralCode }),
    });
    setTokens(res.accessToken, res.refreshToken);
    setUser(res.user);
  };

  const logout = () => {
    clearTokens();
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, refresh }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be inside AuthProvider');
  return ctx;
}
