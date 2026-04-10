import {
  addToCart as medusaAddToCart,
  createCart as medusaCreateCart,
  getCart as medusaGetCart,
  getCollection as medusaGetCollection,
  getCollectionProducts as medusaGetCollectionProducts,
  getCollections as medusaGetCollections,
  getMenu as medusaGetMenu,
  getPage as medusaGetPage,
  getPages as medusaGetPages,
  getProduct as medusaGetProduct,
  getProductRecommendations as medusaGetProductRecommendations,
  getProducts as medusaGetProducts,
  removeFromCart as medusaRemoveFromCart,
  updateCartItem as medusaUpdateCartItem
} from '../medusa';
import type { Cart, Collection, Menu, Page, Product } from './types';

type ExtractVariables<T> = T extends { variables: object } ? T['variables'] : never;

export async function shopifyFetch<T>({ query }: { query: string; variables?: ExtractVariables<T> }) {
  throw new Error(
    `shopifyFetch is disabled. Shopify is not configured for this project. Query: ${query.slice(0, 80)}`
  );
}

export async function createCart(): Promise<Cart> {
  return (await medusaCreateCart()) as unknown as Cart;
}

export async function addToCart(
  cartId: string,
  lines: { merchandiseId: string; quantity: number }[]
): Promise<Cart> {
  const items = lines.map((line) => ({
    variant_id: line.merchandiseId,
    quantity: line.quantity
  }));

  return (await medusaAddToCart(cartId, items)) as unknown as Cart;
}

export async function removeFromCart(cartId: string, lineIds: string[]): Promise<Cart> {
  let updatedCart = (await medusaGetCart(cartId)) as unknown as Cart;

  for (const lineId of lineIds) {
    updatedCart = (await medusaRemoveFromCart(cartId, lineId)) as unknown as Cart;
  }

  return updatedCart;
}

export async function updateCart(
  cartId: string,
  lines: { id: string; merchandiseId: string; quantity: number }[]
): Promise<Cart> {
  let updatedCart = (await medusaGetCart(cartId)) as unknown as Cart;

  for (const line of lines) {
    updatedCart = (await medusaUpdateCartItem(cartId, line.id, line.quantity)) as unknown as Cart;
  }

  return updatedCart;
}

export async function getCart(cartId: string | undefined): Promise<Cart | undefined> {
  return (await medusaGetCart(cartId)) as unknown as Cart | undefined;
}

export async function getCollection(handle: string): Promise<Collection | undefined> {
  return (await medusaGetCollection(handle)) as unknown as Collection | undefined;
}

export async function getCollectionProducts({
  collection,
  reverse,
  sortKey
}: {
  collection: string;
  reverse?: boolean;
  sortKey?: string;
}): Promise<Product[]> {
  return (await medusaGetCollectionProducts({
    collection,
    reverse,
    sortKey: sortKey as any
  })) as unknown as Product[];
}

export async function getCollections(): Promise<Collection[]> {
  return (await medusaGetCollections()) as unknown as Collection[];
}

export async function getMenu(handle: string): Promise<Menu[]> {
  return (await medusaGetMenu(handle)) as unknown as Menu[];
}

export async function getPage(handle: string): Promise<Page> {
  return (await medusaGetPage(handle)) as unknown as Page;
}

export async function getPages(): Promise<Page[]> {
  return (await medusaGetPages()) as unknown as Page[];
}

export async function getProduct(handle: string): Promise<Product | undefined> {
  return (await medusaGetProduct(handle)) as unknown as Product | undefined;
}

export async function getProductRecommendations(productId: string): Promise<Product[]> {
  return (await medusaGetProductRecommendations(productId)) as unknown as Product[];
}

export async function getProducts({
  query,
  reverse,
  sortKey
}: {
  query?: string;
  reverse?: boolean;
  sortKey?: string;
}): Promise<Product[]> {
  return (await medusaGetProducts({
    query,
    reverse,
    sortKey: sortKey as any
  })) as unknown as Product[];
}
