import { getProducts } from 'lib/medusa';

export const metadata = {
  title: 'Products',
  description: 'Browse our collection of products'
};

interface Product {
  id: string;
  title: string;
  handle: string;
  description: string;
  price: number;
}

export default async function Page() {
  try {
    const response: any = await getProducts();
    const products: Product[] = response?.products || [];

    return (
      <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        {/* Hero Section */}
        <div className="mb-12">
          <h1 className="text-4xl font-bold text-gray-900">Products</h1>
          <p className="mt-4 text-lg text-gray-600">
            Discover our carefully curated collection
          </p>
        </div>

        {/* Products Grid */}
        {products.length > 0 ? (
          <div className="grid grid-cols-1 gap-x-6 gap-y-10 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {products.map((product) => (
              <a
                key={product.id}
                href={`/product/${product.handle}`}
                className="group"
              >
                <div className="aspect-h-1 aspect-w-1 w-full overflow-hidden rounded-lg bg-gray-200 group-hover:opacity-75">
                  <div className="h-64 bg-gradient-to-br from-blue-100 to-purple-100 flex items-center justify-center">
                    <span className="text-4xl">📦</span>
                  </div>
                </div>
                <h3 className="mt-4 text-sm font-medium text-gray-900">
                  {product.title}
                </h3>
                <p className="mt-2 text-sm text-gray-500 line-clamp-2">
                  {product.description}
                </p>
                <p className="mt-3 text-lg font-semibold text-gray-900">
                  ${(product.price / 100).toFixed(2)}
                </p>
              </a>
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <p className="text-gray-500 text-lg">No products found</p>
          </div>
        )}
      </div>
    );
  } catch (error) {
    console.error('Error loading products:', error);
    return (
      <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900">Products</h1>
          <p className="mt-4 text-gray-500">Unable to load products. Please try again later.</p>
        </div>
      </div>
    );
  }
}

