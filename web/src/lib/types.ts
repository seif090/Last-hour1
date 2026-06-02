export type UserRole = 'customer' | 'merchant' | 'admin';

export interface User {
  id: string;
  email: string;
  phone?: string;
  role: UserRole;
  isActive: boolean;
  avatarUrl?: string;
  referralCode?: string;
  createdAt: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}

export interface Offer {
  id: string;
  title: string;
  description?: string;
  discountedPrice: number;
  originalPrice: number;
  stockRemaining: number;
  stockInitial: number;
  maxPerCustomer: number;
  imageUrl?: string;
  tags: string[];
  status: string;
  endTime: string;
  store: StoreBrief;
  product: ProductBrief;
  customerPurchasedCount?: number;
}

export interface StoreBrief {
  id: string;
  name: string;
  slug: string;
  cuisineType?: string;
  ratingAvg: number;
  ratingCount: number;
}

export interface ProductBrief {
  id: string;
  name: string;
  category: string;
}

export interface Store {
  id: string;
  name: string;
  slug: string;
  description?: string;
  addressLine1: string;
  city: string;
  cuisineType?: string;
  coverImageUrl?: string;
  logoUrl?: string;
  opensAt?: string;
  closesAt?: string;
  isActive: boolean;
  ratingAvg: number;
  ratingCount: number;
  lat?: number;
  lng?: number;
}

export interface Product {
  id: string;
  name: string;
  description?: string;
  category: string;
  imageUrls: string[];
  originalPrice: number;
  unit: string;
  isActive: boolean;
  sortOrder: number;
}

export interface Order {
  id: string;
  orderNumber: string;
  status: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
  serviceFee: number;
  totalAmount: number;
  discountAmount: number;
  couponCode?: string;
  currency: string;
  notes?: string;
  estimatedReadyAt?: string;
  pickedUpAt?: string;
  cancelledAt?: string;
  cancelReason?: string;
  createdAt: string;
  store: { id: string; name: string; slug: string; addressLine1?: string };
  offer: { id: string; title?: string; imageUrl?: string };
  items?: OrderItem[];
  payment?: PaymentInfo;
}

export interface OrderItem {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface PaymentInfo {
  id: string;
  provider: string;
  status: string;
  amount: number;
  providerTxId?: string;
}

export interface Review {
  id: string;
  rating: number;
  comment?: string;
  imageUrl?: string;
  createdAt: string;
  customer?: { id: string; avatarUrl?: string };
}

export interface Coupon {
  id: string;
  storeId: string;
  code: string;
  discountType: 'percentage' | 'fixed';
  discountValue: number;
  minOrderAmount?: number;
  maxDiscount?: number;
  maxUses: number;
  currentUses: number;
  isActive: boolean;
  startsAt?: string;
  expiresAt?: string;
  description?: string;
  store?: { id: string; name: string };
}

export interface Referral {
  id: string;
  referrerId: string;
  refereeId: string;
  status: 'pending' | 'rewarded' | 'expired';
  rewardAmount?: number;
  createdAt: string;
  referrer?: { id: string; email: string };
  referee?: { id: string; email: string };
}

export interface ReferralInfo {
  code: string;
  totalReferred: number;
  totalRewarded: number;
}

export interface Merchant {
  id: string;
  businessName: string;
  businessType: string;
  description?: string;
  isVerified: boolean;
  userId: string;
  user?: { email: string };
}

export interface StaffMember {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'manager' | 'staff';
  isActive: boolean;
  invitedAt: string;
  joinedAt?: string;
}

export interface AnalyticsDay {
  date: string;
  orders: number;
  revenue: number;
}

export interface MerchantAnalytics {
  totalOrders: number;
  totalRevenue: number;
  daily: AnalyticsDay[];
}

export interface AdminStats {
  totalUsers: number;
  totalMerchants: number;
  totalStores: number;
  totalOrders: number;
  totalRevenue: number;
  activeOffers: number;
  todayOrders: number;
}

export interface Address {
  id: string;
  label: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  district?: string;
  isDefault: boolean;
  latitude?: number;
  longitude?: number;
}

export interface PaginatedResponse<T> {
  data?: T[];
  items?: T[];
  meta: {
    page: number;
    limit: number;
    total: number;
    hasMore: boolean;
  };
  [key: string]: unknown;
}
