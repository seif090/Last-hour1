'use client';

import { useState, useEffect } from 'react';
import { merchantApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { formatPrice } from '@/lib/utils';
import { Package, Clock, Plus } from 'lucide-react';
import { toast } from 'sonner';
import type { Product } from '@/lib/types';

export default function MerchantProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    merchantApi.products.list()
      .then((data: unknown) => {
        const res = data as { products: Product[] };
        setProducts(res.products || []);
      })
      .catch(() => toast.error('Failed to load products'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-primary" /></div>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Products</h1>
        <Button><Plus className="h-4 w-4 mr-1" /> New Product</Button>
      </div>

      {products.length === 0 ? (
        <div className="text-center py-12">
          <Package className="h-12 w-12 text-on-surface-variant/50 mx-auto mb-3" />
          <p className="text-on-surface-variant">No products yet</p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {products.map(product => (
            <Card key={product.id}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between mb-2">
                  <h3 className="font-semibold">{product.name}</h3>
                  <Badge variant={product.isActive ? 'success' : 'danger'}>{product.isActive ? 'Active' : 'Inactive'}</Badge>
                </div>
                {product.description && <p className="text-sm text-on-surface-variant mb-2 line-clamp-2">{product.description}</p>}
                <div className="flex items-center justify-between text-sm">
                  <span className="font-medium">{formatPrice(product.originalPrice)}</span>
                  <span className="text-on-surface-variant">{product.category} · {product.unit}</span>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
