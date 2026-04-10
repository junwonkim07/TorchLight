export type Money = {
  amount: string;
  currencyCode: string;
};

export type Image = {
  url: string;
  altText: string;
  width: number;
  height: number;
};

export type Menu = {
  title: string;
  path: string;
};

export type SEO = {
  title: string;
  description: string;
};

export type ProductOption = {
  id: string;
  name: string;
  values: string[];
};

export type ProductVariant = {
  id: string;
  title: string;
  availableForSale: boolean;
  selectedOptions: {
    name: string;
    value: string;
  }[];
  price: Money;
};

export type Product = {
  id: string;
  handle: string;
  availableForSale: boolean;
  title: string;
  description: string;
  descriptionHtml: string;
  options: ProductOption[];
  priceRange: {
    maxVariantPrice: Money;
    minVariantPrice: Money;
  };
  variants: ProductVariant[];
  featuredImage: Image;
  images: Image[];
  seo: SEO;
  tags: string[];
  updatedAt: string;
};

export type Collection = {
  handle: string;
  title: string;
  description: string;
  seo: SEO;
  path: string;
  updatedAt: string;
};

export type Page = {
  id: string;
  title: string;
  handle: string;
  body: string;
  bodySummary: string;
  seo?: SEO;
  createdAt: string;
  updatedAt: string;
};

export type CartProduct = {
  id: string;
  handle: string;
  title: string;
  featuredImage: Image;
};

export type CartItem = {
  id: string | undefined;
  quantity: number;
  cost: {
    totalAmount: Money;
  };
  merchandise: {
    id: string;
    title: string;
    selectedOptions: {
      name: string;
      value: string;
    }[];
    product: CartProduct;
  };
};

export type Cart = {
  id: string | undefined;
  checkoutUrl: string;
  cost: {
    subtotalAmount: Money;
    totalTaxAmount: Money;
    totalAmount: Money;
    totalDutyAmount?: Money;
  };
  lines: CartItem[];
  totalQuantity: number;
  note?: string;
};

export type MedusaPrice = {
  id?: string;
  amount?: number;
  currency_code?: string;
  region_id?: string;
  min_quantity?: number;
  max_quantity?: number;
};

export type MedusaCalculatedPrice = {
  calculated_amount?: number;
  original_amount?: number;
  currency_code?: string;
  calculated_price?: {
    price_list_type?: string;
  };
};

export type MedusaVariantOption = {
  option_id?: string;
  value?: string;
  option?: {
    title?: string;
  };
};

export type MedusaVariant = {
  id: string;
  title?: string;
  sku?: string;
  barcode?: string;
  inventory_quantity?: number;
  allow_backorder?: boolean;
  manage_inventory?: boolean;
  prices?: MedusaPrice[];
  options?: MedusaVariantOption[];
  calculated_price?: MedusaCalculatedPrice;
};

export type MedusaProductTag = {
  id?: string;
  value?: string;
};

export type MedusaProductOptionValue = {
  id?: string;
  value?: string;
};

export type MedusaProductOption = {
  id?: string;
  title?: string;
  values?: Array<MedusaProductOptionValue | string>;
};

export type MedusaProduct = {
  id: string;
  title: string;
  handle: string;
  description?: string;
  thumbnail?: string;
  created_at?: string;
  updated_at?: string;
  images?: Array<{
    url?: string;
    alt_text?: string;
    width?: number;
    height?: number;
  }>;
  options?: MedusaProductOption[];
  variants?: MedusaVariant[];
  tags?: Array<MedusaProductTag | string>;
};

export type MedusaCollection = {
  id: string;
  title: string;
  handle: string;
  metadata?: Record<string, unknown>;
  created_at?: string;
  updated_at?: string;
};

export type MedusaCartItem = {
  id: string;
  quantity: number;
  title?: string;
  subtitle?: string;
  thumbnail?: string;
  unit_price?: number;
  total?: number;
  variant_id?: string;
  variant?: MedusaVariant & {
    product?: MedusaProduct;
  };
  product?: MedusaProduct;
};

export type MedusaCart = {
  id: string;
  checkout_url?: string;
  currency_code?: string;
  subtotal?: number;
  tax_total?: number;
  total?: number;
  shipping_total?: number;
  discount_total?: number;
  items?: MedusaCartItem[];
};

export type MedusaProductListResponse = {
  products?: MedusaProduct[];
  count?: number;
  limit?: number;
  offset?: number;
};

export type MedusaCollectionListResponse = {
  collections?: MedusaCollection[];
  count?: number;
  limit?: number;
  offset?: number;
};

export type MedusaCartResponse = {
  cart?: MedusaCart;
};
