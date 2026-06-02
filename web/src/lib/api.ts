const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1';

let accessToken: string | null = null;
let refreshToken: string | null = null;
let onAuthError: (() => void) | null = null;

export function setTokens(access: string, refresh: string) {
  accessToken = access;
  refreshToken = refresh;
  if (typeof window !== 'undefined') {
    localStorage.setItem('accessToken', access);
    localStorage.setItem('refreshToken', refresh);
  }
}

export function loadTokens() {
  if (typeof window !== 'undefined') {
    accessToken = localStorage.getItem('accessToken');
    refreshToken = localStorage.getItem('refreshToken');
  }
}

export function clearTokens() {
  accessToken = null;
  refreshToken = null;
  if (typeof window !== 'undefined') {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
  }
}

export function setOnAuthError(cb: () => void) {
  onAuthError = cb;
}

export function getAccessToken() {
  return accessToken;
}

async function refreshAccessToken(): Promise<boolean> {
  if (!refreshToken) return false;
  try {
    const res = await fetch(`${API_URL}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });
    if (!res.ok) return false;
    const data = await res.json();
    setTokens(data.accessToken, data.refreshToken);
    return true;
  } catch {
    return false;
  }
}

export async function api<T = unknown>(
  endpoint: string,
  options: RequestInit = {},
): Promise<T> {
  loadTokens();

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (accessToken) {
    headers['Authorization'] = `Bearer ${accessToken}`;
  }

  let res = await fetch(`${API_URL}${endpoint}`, { ...options, headers });

  if (res.status === 401 && refreshToken) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      headers['Authorization'] = `Bearer ${accessToken}`;
      res = await fetch(`${API_URL}${endpoint}`, { ...options, headers });
    } else {
      clearTokens();
      onAuthError?.();
      throw new Error('Session expired');
    }
  }

  if (!res.ok) {
    const error = await res.json().catch(() => ({ message: 'Request failed' }));
    throw new Error(error.message || `HTTP ${res.status}`);
  }

  if (res.status === 204) return undefined as T;
  return res.json();
}

export const authApi = {
  login: (email: string, password: string) =>
    api<{ accessToken: string; refreshToken: string; user: unknown }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),
  register: (data: { email: string; password: string; role?: string; referralCode?: string }) =>
    api<{ accessToken: string; refreshToken: string; user: unknown }>('/auth/register', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  profile: () => api<unknown>('/auth/profile'),
};

export const offersApi = {
  list: (params?: { lat?: number; lng?: number; radiusM?: number; category?: string; page?: number; limit?: number }) => {
    const search = new URLSearchParams();
    if (params?.lat !== undefined) search.set('lat', String(params.lat));
    if (params?.lng !== undefined) search.set('lng', String(params.lng));
    if (params?.radiusM) search.set('radiusM', String(params.radiusM));
    if (params?.category) search.set('category', params.category);
    if (params?.page) search.set('page', String(params.page));
    if (params?.limit) search.set('limit', String(params.limit));
    const qs = search.toString();
    return api<{ offers: unknown[]; meta: unknown }>(`/offers${qs ? `?${qs}` : ''}`);
  },
  get: (id: string) => api<unknown>(`/offers/${id}`),
  search: (params: { q: string; lat?: number; lng?: number; page?: number; limit?: number }) => {
    const search = new URLSearchParams({ q: params.q });
    if (params.lat !== undefined) search.set('lat', String(params.lat));
    if (params.lng !== undefined) search.set('lng', String(params.lng));
    return api<{ offers: unknown[]; meta: unknown }>(`/offers/search?${search.toString()}`);
  },
};

export const storesApi = {
  get: (id: string) => api<unknown>(`/stores/${id}`),
  nearby: (params: { lat: number; lng: number; radiusM?: number }) => {
    const search = new URLSearchParams({ lat: String(params.lat), lng: String(params.lng) });
    if (params.radiusM) search.set('radiusM', String(params.radiusM));
    return api<{ stores: unknown[] }>(`/stores/nearby?${search.toString()}`);
  },
};

export const ordersApi = {
  place: (data: { offerId: string; quantity: number; payment: { provider: string }; notes?: string; couponCode?: string }) =>
    api<{ order: unknown; payment: unknown }>('/orders', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  list: (params?: { status?: string; page?: number; limit?: number }) => {
    const search = new URLSearchParams();
    if (params?.status) search.set('status', params.status);
    if (params?.page) search.set('page', String(params.page));
    if (params?.limit) search.set('limit', String(params.limit));
    const qs = search.toString();
    return api<{ orders: unknown[]; meta: unknown }>(`/orders${qs ? `?${qs}` : ''}`);
  },
  get: (id: string) => api<unknown>(`/orders/${id}`),
  confirmPickup: (id: string) =>
    api(`/orders/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status: 'picked_up' }),
    }),
  cancel: (id: string, reason?: string) =>
    api(`/orders/${id}/cancel`, {
      method: 'PATCH',
      body: JSON.stringify({ reason }),
    }),
};

export const favoritesApi = {
  list: () => api<unknown[]>('/favorites'),
  add: (offerId: string) =>
    api('/favorites', { method: 'POST', body: JSON.stringify({ offerId }) }),
  remove: (offerId: string) =>
    api(`/favorites/${offerId}`, { method: 'DELETE' }),
};

export const reviewsApi = {
  create: (data: { orderId: string; rating: number; comment?: string; imageUrl?: string }) =>
    api('/reviews', { method: 'POST', body: JSON.stringify(data) }),
  store: (storeId: string, page?: number) => {
    const search = page ? `?page=${page}` : '';
    return api<{ reviews: unknown[]; meta: unknown }>(`/reviews/store/${storeId}${search}`);
  },
};

export const addressesApi = {
  list: () => api<unknown[]>('/addresses'),
  create: (data: { label: string; addressLine1: string; city: string; isDefault?: boolean }) =>
    api('/addresses', { method: 'POST', body: JSON.stringify(data) }),
  update: (id: string, data: Record<string, unknown>) =>
    api(`/addresses/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
  delete: (id: string) => api(`/addresses/${id}`, { method: 'DELETE' }),
};

export const merchantApi = {
  register: (data: { businessName: string; businessType: string; description?: string; taxId?: string }) =>
    api('/merchant/register', { method: 'POST', body: JSON.stringify(data) }),
  dashboard: () => api<{ stores: unknown[] }>('/merchant/dashboard'),
  todaySales: () => api<unknown>('/merchant/today-sales'),
  listOrders: (params?: { status?: string; page?: number; limit?: number }) => {
    const search = new URLSearchParams();
    if (params?.status) search.set('status', params.status);
    if (params?.page) search.set('page', String(params.page));
    if (params?.limit) search.set('limit', String(params.limit));
    const qs = search.toString();
    return api<{ orders: unknown[]; meta: unknown }>(`/merchant/orders${qs ? `?${qs}` : ''}`);
  },
  analytics: (days = 7) => api<unknown>(`/merchant/analytics?days=${days}`),
  coupons: {
    list: () => api<unknown[]>('/merchant/coupons'),
    create: (data: { storeId: string; code: string; discountType: string; discountValue: number; maxUses?: number; description?: string; minOrderAmount?: number; maxDiscount?: number }) =>
      api('/merchant/coupons', { method: 'POST', body: JSON.stringify(data) }),
    toggle: (id: string) => api(`/merchant/coupons/${id}/toggle`, { method: 'PATCH' }),
  },
  offers: {
    list: () => api<{ offers: unknown[] }>('/merchant/offers'),
    create: (data: Record<string, unknown>) =>
      api('/merchant/offers', { method: 'POST', body: JSON.stringify(data) }),
    update: (id: string, data: Record<string, unknown>) =>
      api(`/merchant/offers/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
  },
  products: {
    list: () => api<{ products: unknown[] }>('/merchant/products'),
    create: (data: Record<string, unknown>) =>
      api('/merchant/products', { method: 'POST', body: JSON.stringify(data) }),
    update: (id: string, data: Record<string, unknown>) =>
      api(`/merchant/products/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
    delete: (id: string) => api(`/merchant/products/${id}`, { method: 'DELETE' }),
  },
  staff: {
    list: () => api<unknown[]>('/merchant/staff'),
    invite: (data: { email: string; name: string; role: string }) =>
      api('/merchant/staff', { method: 'POST', body: JSON.stringify(data) }),
    update: (id: string, data: Record<string, unknown>) =>
      api(`/merchant/staff/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
    remove: (id: string) => api(`/merchant/staff/${id}`, { method: 'DELETE' }),
  },
};

export const adminApi = {
  stats: () => api<unknown>('/admin/stats'),
  users: (page?: number) => api<unknown>(`/admin/users${page ? `?page=${page}` : ''}`),
  merchants: (page?: number) => api<unknown>(`/admin/merchants${page ? `?page=${page}` : ''}`),
  coupons: (page?: number) => api<unknown>(`/admin/coupons${page ? `?page=${page}` : ''}`),
  referrals: (page?: number) => api<unknown>(`/admin/referrals${page ? `?page=${page}` : ''}`),
  referralStats: () => api<unknown>('/admin/referrals/stats'),
  health: () => api<{ status: string; uptime: number; timestamp: string }>('/health'),
};
