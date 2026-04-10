import { DEFAULT_OPTION, HIDDEN_PRODUCT_TAG, MEDUSA_API_URL, TAGS } from '../constants';
import {
  Cart,
  CartItem,
  Collection,
  Image,
  MedusaCart,
  MedusaCartItem,
  MedusaCartResponse,
  MedusaCollection,
  MedusaCollectionListResponse,
  MedusaProduct,
  MedusaProductListResponse,
  MedusaVariant,
  Menu,
  Money,
  Page,
  Product,
  ProductOption,
  ProductVariant
} from './types';

type SortKey = 'RELEVANCE' | 'BEST_SELLING' | 'CREATED_AT' | 'PRICE' | 'created_at';

const DEFAULT_CURRENCY_CODE = (process.env.NEXT_PUBLIC_DEFAULT_CURRENCY || 'USD').toUpperCase();
const PLACEHOLDER_IMAGE_URL = 'https://dummyimage.com/1200x1200/e5e7eb/9ca3af';
const MEDUSA_PUBLISHABLE_KEY = process.env.NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY;

const toMajorUnitString = (value?: number | string | null): string => {
  if (value === undefined || value === null || value === '') {
    return '0.00';
  }

  const raw = String(value);
  const numericValue = Number(raw);

  if (!Number.isFinite(numericValue)) {
    return '0.00';
  }

  // Medusa amounts are usually minor units (cents), but keep decimal values as-is.
  if (raw.includes('.')) {
    return numericValue.toFixed(2);
  }

  return (numericValue / 100).toFixed(2);
};

const normalizeCurrencyCode = (currencyCode?: string | null): string =>
  (currencyCode || DEFAULT_CURRENCY_CODE).toUpperCase();

const normalizeMoney = (amount?: number | string | null, currencyCode?: string | null): Money => ({
  amount: toMajorUnitString(amount),
  currencyCode: normalizeCurrencyCode(currencyCode)
});

const imageFromUrl = (url: string, altText: string): Image => ({
  url,
  altText,
  width: 1200,
  height: 1200
});

const normalizeImage = (
  image: { url?: string; alt_text?: string; altText?: string; width?: number; height?: number } | undefined,
  fallbackAlt: string
): Image => ({
  url: image?.url || PLACEHOLDER_IMAGE_URL,
  altText: image?.alt_text || image?.altText || fallbackAlt,
  width: image?.width || 1200,
  height: image?.height || 1200
});

const normalizeTag = (tag: unknown): string | null => {
  if (typeof tag === 'string') {
    return tag;
  }

  if (tag && typeof tag === 'object' && 'value' in tag) {
    const value = (tag as { value?: string }).value;
    return value || null;
  }

  return null;
};

const getVariantRawAmount = (variant: MedusaVariant): number => {
  const amount =
    variant.calculated_price?.calculated_amount ??
    variant.prices?.[0]?.amount ??
    variant.calculated_price?.original_amount ??
    0;

  return Number(amount) || 0;
};

const getVariantCurrencyCode = (variant: MedusaVariant): string =>
  normalizeCurrencyCode(variant.calculated_price?.currency_code || variant.prices?.[0]?.currency_code);

const isVariantAvailableForSale = (variant: MedusaVariant): boolean => {
  if (variant.allow_backorder) {
    return true;
  }

  if (variant.manage_inventory && typeof variant.inventory_quantity === 'number') {
    return variant.inventory_quantity > 0;
  }

  if (typeof variant.inventory_quantity === 'number') {
    return variant.inventory_quantity > 0;
  }

  return true;
};

const normalizeProductOptions = (product: MedusaProduct): ProductOption[] => {
  const normalized =
    product.options?.map((option, index) => {
      const values = (option.values || [])
        .map((value) => (typeof value === 'string' ? value : value?.value || ''))
        .filter(Boolean);

      return {
        id: option.id || `option-${index}`,
        name: option.title || `Option ${index + 1}`,
        values: values.length > 0 ? values : [DEFAULT_OPTION]
      };
    }) || [];

  return normalized;
};

const normalizeVariantSelectedOptions = (
  variant: MedusaVariant,
  optionNamesById: Map<string, string>
): ProductVariant['selectedOptions'] => {
  const options =
    variant.options
      ?.map((option, index) => {
        const name =
          (option.option_id ? optionNamesById.get(option.option_id) : undefined) ||
          option.option?.title ||
          `Option ${index + 1}`;
        const value = option.value || DEFAULT_OPTION;

        return {
          name,
          value
        };
      })
      .filter((option) => option.name && option.value) || [];

  if (options.length > 0) {
    return options;
  }

  return [{ name: 'Title', value: DEFAULT_OPTION }];
};

const normalizeProduct = (
  rawProduct: MedusaProduct,
  filterHiddenProducts: boolean = true
): Product | undefined => {
  const tags = (rawProduct.tags || []).map(normalizeTag).filter(Boolean) as string[];

  if (filterHiddenProducts && tags.includes(HIDDEN_PRODUCT_TAG)) {
    return undefined;
  }

  const images =
    rawProduct.images?.map((image) => normalizeImage(image, rawProduct.title)).filter(Boolean) || [];

  if (images.length === 0) {
    images.push(imageFromUrl(rawProduct.thumbnail || PLACEHOLDER_IMAGE_URL, rawProduct.title));
  }

  const featuredImage = images[0];
  const options = normalizeProductOptions(rawProduct);
  const optionNamesById = new Map(options.map((option) => [option.id, option.name]));

  const variants: ProductVariant[] =
    rawProduct.variants?.map((variant) => {
      const amount = getVariantRawAmount(variant);
      const currencyCode = getVariantCurrencyCode(variant);

      return {
        id: variant.id,
        title: variant.title || rawProduct.title,
        availableForSale: isVariantAvailableForSale(variant),
        selectedOptions: normalizeVariantSelectedOptions(variant, optionNamesById),
        price: normalizeMoney(amount, currencyCode)
      };
    }) || [];

  if (variants.length === 0) {
    variants.push({
      id: rawProduct.id,
      title: rawProduct.title,
      availableForSale: true,
      selectedOptions: [{ name: 'Title', value: DEFAULT_OPTION }],
      price: normalizeMoney(0, DEFAULT_CURRENCY_CODE)
    });
  }

  const variantPrices = variants.map((variant) => Number(variant.price.amount) || 0);
  const minVariantPrice = Math.min(...variantPrices);
  const maxVariantPrice = Math.max(...variantPrices);

  return {
    id: rawProduct.id,
    handle: rawProduct.handle,
    availableForSale: variants.some((variant) => variant.availableForSale),
    title: rawProduct.title,
    description: rawProduct.description || '',
    descriptionHtml: rawProduct.description || '',
    options,
    priceRange: {
      minVariantPrice: {
        amount: minVariantPrice.toFixed(2),
        currencyCode: variants[0]?.price.currencyCode || DEFAULT_CURRENCY_CODE
      },
      maxVariantPrice: {
        amount: maxVariantPrice.toFixed(2),
        currencyCode: variants[0]?.price.currencyCode || DEFAULT_CURRENCY_CODE
      }
    },
    variants,
    featuredImage,
    images,
    seo: {
      title: rawProduct.title,
      description: rawProduct.description || rawProduct.title
    },
    tags,
    updatedAt: rawProduct.updated_at || rawProduct.created_at || new Date().toISOString()
  };
};

const sortProducts = (products: Product[], sortKey: SortKey, reverse: boolean): Product[] => {
  const sorted = [...products];

  if (sortKey === 'PRICE') {
    sorted.sort(
      (first, second) =>
        Number(first.priceRange.minVariantPrice.amount) - Number(second.priceRange.minVariantPrice.amount)
    );
  }

  if (sortKey === 'CREATED_AT' || sortKey === 'created_at') {
    sorted.sort((first, second) => {
      const firstValue = new Date(first.updatedAt).getTime();
      const secondValue = new Date(second.updatedAt).getTime();
      return firstValue - secondValue;
    });
  }

  if (reverse) {
    sorted.reverse();
  }

  return sorted;
};

const extractCollectionDescription = (collection: MedusaCollection): string => {
  const description = collection.metadata?.description;
  return typeof description === 'string' ? description : '';
};

const normalizeCollection = (collection: MedusaCollection): Collection => ({
  handle: collection.handle,
  title: collection.title,
  description: extractCollectionDescription(collection),
  seo: {
    title: collection.title,
    description: extractCollectionDescription(collection) || `${collection.title} products`
  },
  path: `/search/${collection.handle}`,
  updatedAt: collection.updated_at || collection.created_at || new Date().toISOString()
});

const extractCartPayload = (payload: unknown): MedusaCart | undefined => {
  if (!payload || typeof payload !== 'object') {
    return undefined;
  }

  const data = payload as {
    cart?: MedusaCart;
    parent?: MedusaCart;
    data?: { cart?: MedusaCart; parent?: MedusaCart };
  };

  return data.cart || data.parent || data.data?.cart || data.data?.parent;
};

const normalizeCartLineItem = (line: MedusaCartItem, cartCurrencyCode: string): CartItem => {
  const currencyCode = normalizeCurrencyCode(
    line.variant?.calculated_price?.currency_code || cartCurrencyCode
  );

  const rawLineTotal = line.total ?? (line.unit_price || 0) * (line.quantity || 1);
  const product = line.product || line.variant?.product;
  const fallbackImageUrl = line.thumbnail || product?.thumbnail || PLACEHOLDER_IMAGE_URL;

  return {
    id: line.id,
    quantity: line.quantity,
    cost: {
      totalAmount: normalizeMoney(rawLineTotal, currencyCode)
    },
    merchandise: {
      id: line.variant_id || line.variant?.id || line.id,
      title: line.title || line.variant?.title || product?.title || 'Product',
      selectedOptions:
        line.variant?.options
          ?.map((option, index) => ({
            name: option.option?.title || `Option ${index + 1}`,
            value: option.value || DEFAULT_OPTION
          }))
          .filter((option) => option.value) || [],
      product: {
        id: product?.id || line.id,
        handle: product?.handle || '',
        title: product?.title || line.title || 'Product',
        featuredImage: imageFromUrl(fallbackImageUrl, product?.title || line.title || 'Product')
      }
    }
  };
};

const normalizeCart = (cart: MedusaCart): Cart => {
  const currencyCode = normalizeCurrencyCode(cart.currency_code);
  const lines = (cart.items || []).map((line) => normalizeCartLineItem(line, currencyCode));
  const totalQuantity = lines.reduce((total, line) => total + line.quantity, 0);

  const fallbackSubtotal = lines.reduce(
    (total, line) => total + Number(line.cost.totalAmount.amount),
    0
  );

  return {
    id: cart.id,
    checkoutUrl: cart.checkout_url || `/checkout/${cart.id}`,
    cost: {
      subtotalAmount:
        cart.subtotal !== undefined
          ? normalizeMoney(cart.subtotal, currencyCode)
          : { amount: fallbackSubtotal.toFixed(2), currencyCode },
      totalTaxAmount: normalizeMoney(cart.tax_total || 0, currencyCode),
      totalAmount:
        cart.total !== undefined
          ? normalizeMoney(cart.total, currencyCode)
          : { amount: fallbackSubtotal.toFixed(2), currencyCode }
    },
    lines,
    totalQuantity
  };
};

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
  body?: unknown;
}): Promise<T> {
  const requestHeaders: HeadersInit = {
    'Content-Type': 'application/json',
    ...(MEDUSA_PUBLISHABLE_KEY ? { 'x-publishable-api-key': MEDUSA_PUBLISHABLE_KEY } : {}),
    ...headers
  };

  const requestConfig: RequestInit & { next?: { tags: string[] } } = {
    method,
    headers: requestHeaders,
    cache
  };

  if (body !== undefined) {
    requestConfig.body = JSON.stringify(body);
  }

  if (tags && tags.length > 0) {
    requestConfig.next = { tags };
  }

  const response = await fetch(`${MEDUSA_API_URL}${endpoint}`, requestConfig);

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData?.message || `Medusa API error: ${response.status} ${response.statusText}`);
  }

  return response.json();
}

export async function getProduct(handle: string): Promise<Product | undefined> {
  const response = await medusaFetch<MedusaProductListResponse>({
    endpoint: `/store/products?handle=${encodeURIComponent(handle)}`,
    tags: [TAGS.products]
  });

  const rawProduct = response.products?.[0];
  return rawProduct ? normalizeProduct(rawProduct, false) : undefined;
}

export async function getProducts({
  sortKey = 'RELEVANCE',
  reverse = false,
  search,
  query
}: {
  sortKey?: SortKey;
  reverse?: boolean;
  search?: string;
  query?: string;
} = {}): Promise<Product[]> {
  const searchTerm = query || search;
  const searchQuery = searchTerm ? `&q=${encodeURIComponent(searchTerm)}` : '';

  const response = await medusaFetch<MedusaProductListResponse>({
    endpoint: `/store/products?limit=100${searchQuery}`,
    tags: [TAGS.products]
  });

  const products = (response.products || [])
    .map((rawProduct) => normalizeProduct(rawProduct))
    .filter(Boolean) as Product[];

  return sortProducts(products, sortKey, reverse);
}

export async function getCollection(handle: string): Promise<Collection | undefined> {
  const response = await medusaFetch<MedusaCollectionListResponse>({
    endpoint: `/store/collections?handle=${encodeURIComponent(handle)}`,
    tags: [TAGS.collections]
  });

  const collection = response.collections?.[0];
  return collection ? normalizeCollection(collection) : undefined;
}

export async function getCollectionProducts({
  collection,
  reverse = false,
  sortKey = 'RELEVANCE'
}: {
  collection: string;
  reverse?: boolean;
  sortKey?: SortKey;
}): Promise<Product[]> {
  let products: Product[] = [];

  try {
    const collectionResponse = await medusaFetch<MedusaCollectionListResponse>({
      endpoint: `/store/collections?handle=${encodeURIComponent(collection)}`,
      tags: [TAGS.collections]
    });

    const collectionId = collectionResponse.collections?.[0]?.id;

    if (collectionId) {
      const response = await medusaFetch<MedusaProductListResponse>({
        endpoint: `/store/products?collection_id[]=${encodeURIComponent(collectionId)}&limit=100`,
        tags: [TAGS.collections, TAGS.products]
      });

      products = (response.products || [])
        .map((rawProduct) => normalizeProduct(rawProduct))
        .filter(Boolean) as Product[];
    }
  } catch {
    products = [];
  }

  if (products.length === 0) {
    const response = await medusaFetch<MedusaProductListResponse>({
      endpoint: `/store/products?collection_handle=${encodeURIComponent(collection)}&limit=100`,
      tags: [TAGS.collections, TAGS.products]
    });

    products = (response.products || [])
      .map((rawProduct) => normalizeProduct(rawProduct))
      .filter(Boolean) as Product[];
  }

  if (products.length === 0 && collection.startsWith('hidden-homepage')) {
    const fallbackProducts = await getProducts({
      sortKey: 'CREATED_AT',
      reverse: true
    });

    return collection.includes('featured') ? fallbackProducts.slice(0, 3) : fallbackProducts.slice(0, 12);
  }

  return sortProducts(products, sortKey, reverse);
}

export async function getCollections(): Promise<Collection[]> {
  const response = await medusaFetch<MedusaCollectionListResponse>({
    endpoint: '/store/collections?limit=100',
    tags: [TAGS.collections]
  });

  const collections = (response.collections || []).map(normalizeCollection);

  return [
    {
      handle: '',
      title: 'All',
      description: 'All products',
      seo: {
        title: 'All',
        description: 'All products'
      },
      path: '/search',
      updatedAt: new Date().toISOString()
    },
    ...collections.filter((collection) => !collection.handle.startsWith('hidden'))
  ];
}

export async function getProductRecommendations(productId: string): Promise<Product[]> {
  const products = await getProducts({ sortKey: 'CREATED_AT', reverse: true });
  return products.filter((product) => product.id !== productId).slice(0, 8);
}

export async function getMenu(handle: string): Promise<Menu[]> {
  const collections = await getCollections();
  const collectionItems = collections
    .filter((collection) => collection.handle)
    .slice(0, 4)
    .map((collection) => ({
      title: collection.title,
      path: collection.path
    }));

  if (handle.includes('footer')) {
    return [
      { title: 'Home', path: '/' },
      { title: 'Products', path: '/search' },
      ...collectionItems
    ];
  }

  return [{ title: 'Products', path: '/search' }, ...collectionItems];
}

export async function getCart(cartId?: string): Promise<Cart | undefined> {
  if (!cartId) {
    return undefined;
  }

  try {
    const response = await medusaFetch<MedusaCartResponse>({
      endpoint: `/store/carts/${cartId}`,
      tags: [TAGS.cart]
    });

    const cart = extractCartPayload(response);
    return cart ? normalizeCart(cart) : undefined;
  } catch {
    return undefined;
  }
}

export async function createCart(input?: Record<string, unknown>): Promise<Cart> {
  const regionId = process.env.NEXT_PUBLIC_MEDUSA_REGION_ID;
  const response = await medusaFetch<MedusaCartResponse>({
    endpoint: '/store/carts',
    method: 'POST',
    cache: 'no-store',
    body: {
      ...(regionId ? { region_id: regionId } : {}),
      ...(input || {})
    },
    tags: [TAGS.cart]
  });

  const cart = extractCartPayload(response);

  if (!cart) {
    throw new Error('Unable to create cart');
  }

  return normalizeCart(cart);
}

export async function addToCart(
  cartId: string,
  items: Array<{ variant_id: string; quantity: number }>
): Promise<Cart> {
  const response = await medusaFetch<MedusaCartResponse>({
    endpoint: `/store/carts/${cartId}/line-items`,
    method: 'POST',
    cache: 'no-store',
    body: { items },
    tags: [TAGS.cart]
  });

  const cart = extractCartPayload(response);

  if (!cart) {
    const refreshedCart = await getCart(cartId);
    if (!refreshedCart) {
      throw new Error('Unable to update cart after add item');
    }
    return refreshedCart;
  }

  return normalizeCart(cart);
}

export async function updateCartItem(
  cartId: string,
  lineId: string,
  quantity: number
): Promise<Cart> {
  const response = await medusaFetch<MedusaCartResponse>({
    endpoint: `/store/carts/${cartId}/line-items/${lineId}`,
    method: 'POST',
    cache: 'no-store',
    body: { quantity },
    tags: [TAGS.cart]
  });

  const cart = extractCartPayload(response);

  if (!cart) {
    const refreshedCart = await getCart(cartId);
    if (!refreshedCart) {
      throw new Error('Unable to update cart item');
    }
    return refreshedCart;
  }

  return normalizeCart(cart);
}

export async function removeFromCart(cartId: string, lineId: string): Promise<Cart> {
  const response = await medusaFetch<MedusaCartResponse>({
    endpoint: `/store/carts/${cartId}/line-items/${lineId}`,
    method: 'DELETE',
    cache: 'no-store',
    tags: [TAGS.cart]
  });

  const cart = extractCartPayload(response);

  if (!cart) {
    const refreshedCart = await getCart(cartId);
    if (!refreshedCart) {
      throw new Error('Unable to remove cart item');
    }
    return refreshedCart;
  }

  return normalizeCart(cart);
}

export async function updateCart(
  cartId: string,
  data: Record<string, unknown>
): Promise<Cart> {
  const response = await medusaFetch<MedusaCartResponse>({
    endpoint: `/store/carts/${cartId}`,
    method: 'POST',
    cache: 'no-store',
    body: data,
    tags: [TAGS.cart]
  });

  const cart = extractCartPayload(response);

  if (!cart) {
    const refreshedCart = await getCart(cartId);
    if (!refreshedCart) {
      throw new Error('Unable to update cart');
    }
    return refreshedCart;
  }

  return normalizeCart(cart);
}

export async function getPage(handle: string): Promise<Page> {
  const now = new Date().toISOString();
  return {
    id: handle,
    title: handle,
    handle,
    body: '',
    bodySummary: '',
    createdAt: now,
    updatedAt: now
  };
}

export async function getPages(): Promise<Page[]> {
  return [];
}
