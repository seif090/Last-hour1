declare module 'express' {
  interface Request {
    requestId?: string;
    user?: {
      id: string;
      email: string;
      role: string;
      merchantId?: string;
      storeId?: string;
    };
  }
}
