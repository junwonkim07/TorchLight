import { MEDUSA_API_URL } from '../constants';

export async function medusaFetch<T>({
  cache = 'force-cache',
  endpoint,
  headers,
  method = 'GET',
  tags,
  body
}: {
  cache?: RequestCache;
  endpoint: string;
  headers?: HeadersInit;
  method?: string;
  tags?: string[];
  body?: any;
}): Promise<T> {
  try {
    const config: RequestInit = {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...headers
      },
      cache
    };

    if (body) {
      config.body = JSON.stringify(body);
    }

    if (tags) {
      config.next = { tags };
    }

    const url = `${MEDUSA_API_URL}${endpoint}`;
    const response = await fetch(url, config);

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(
        errorData?.message || `API Error: ${response.status} ${response.statusText}`
      );
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Medusa API error:', error);
    throw error;
  }
}

// Product queries
export async function getProduct(handle: string) {
  return medusaFetch({
    endpoint: `/store/products?handle=${handle}`,
    tags: ['product']
  });
}

export async function getProducts({
  sortKey = 'created_at',
  reverse = false,
  search
}: {
  sortKey?: string;
  reverse?: boolean;
  search?: string;
} = {}) {
  let query = `/store/products?limit=100`;
  if (search) {
    query += `&q=${encodeURIComponent(search)}`;
  }
  if (sortKey === 'PRICE') {
    query += `&order=${reverse ? 'desc' : 'asc'}`;
  }

  return medusaFetch({
    endpoint: query,
    tags: ['products']
  });
}

export async function getProductsByCollection(collectionHandle: string) {
  return medusaFetch({
    endpoint: `/store/products?collection_handle=${collectionHandle}`,
    tags: ['products', 'collections']
  });
}

// Collection queries
export async function getCollection(handle: string) {
  return medusaFetch({
    endpoint: `/store/collections?handle=${handle}`,
    tags: ['collections']
  });
}

export async function getCollections() {
  return medusaFetch({
    endpoint: `/store/collections`,
    tags: ['collections']
  });
}

// Cart operations
export async function getCart(cartId: string) {
  return medusaFetch({
    endpoint: `/store/carts/${cartId}`,
    tags: ['cart']
  });
}

export async function createCart(input?: any) {
  return medusaFetch({
    endpoint: `/store/carts`,
    method: 'POST',
    body: input || {},
    tags: ['cart']
  });
}

export async function addToCart(cartId: string, items: any[]) {
  return medusaFetch({
    endpoint: `/store/carts/${cartId}/line-items`,
    method: 'POST',
    body: { items },
    tags: ['cart']
  });
}

export async function updateCart(cartId: string, data: any) {
  return medusaFetch({
    endpoint: `/store/carts/${cartId}`,
    method: 'POST',
    body: data,
    tags: ['cart']
  });
}

export async function removeFromCart(cartId: string, lineId: string) {
  return medusaFetch({
    endpoint: `/store/carts/${cartId}/line-items/${lineId}`,
    method: 'DELETE',
    tags: ['cart']
  });
}

export async function updateCartItem(cartId: string, lineId: string, quantity: number) {
  return medusaFetch({
    endpoint: `/store/carts/${cartId}/line-items/${lineId}`,
    method: 'POST',
    body: { quantity },
    tags: ['cart']
  });
}

// Pages / CMS (placeholder - implement based on your CMS)
export async function getPages() {
  // If you're using a separate CMS like Medusa's content module or another service,
  // implement accordingly
  return [];
}
