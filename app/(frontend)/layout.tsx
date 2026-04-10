import { CartProvider } from 'components/cart/cart-context';
import { ThemeProvider } from 'components/react-bricks/theme-provider';
import { WelcomeToast } from 'components/welcome-toast';
import { getCart } from 'lib/medusa';
import { ensureStartsWith } from 'lib/utils';
import { cookies } from 'next/headers';
import { ReactNode } from 'react';
import { Toaster } from 'sonner';
import '../globals.css';
import './styles.css';

const { TWITTER_CREATOR, TWITTER_SITE, SITE_NAME } = process.env;
const baseUrl = process.env.NEXT_PUBLIC_VERCEL_URL
  ? `https://${process.env.NEXT_PUBLIC_VERCEL_URL}`
  : 'http://localhost:3000';
const twitterCreator = TWITTER_CREATOR ? ensureStartsWith(TWITTER_CREATOR, '@') : undefined;
const twitterSite = TWITTER_SITE ? ensureStartsWith(TWITTER_SITE, 'https://') : undefined;

export const metadata = {
  metadataBase: new URL(baseUrl),
  title: {
    default: SITE_NAME!,
    template: `%s | ${SITE_NAME}`
  },
  robots: {
    follow: true,
    index: true
  },
  ...(twitterCreator &&
    twitterSite && {
    twitter: {
      card: 'summary_large_image',
      creator: twitterCreator,
      site: twitterSite
    }
  })
};

export default async function RootLayout({ children }: { children: ReactNode }) {
  const cartId = cookies().get('cartId')?.value;
  const cart = getCart(cartId);

  return (
    <ThemeProvider attribute="class" defaultTheme="light" enableSystem={false}>
      <CartProvider cartPromise={cart}>
        <div className="flex flex-col min-h-screen bg-white dark:bg-white">
          {/* Header */}
          <header className="border-b bg-white">
            <nav className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
              <div className="flex h-16 items-center justify-between">
                <a href="/" className="text-2xl font-bold text-gray-900">
                  {SITE_NAME}
                </a>
                <div className="flex items-center gap-4">
                  <a href="/" className="text-gray-700 hover:text-gray-900">
                    상품
                  </a>
                </div>
              </div>
            </nav>
          </header>

          {/* Main Content */}
          <main className="flex-1 bg-white">
            {children}
          </main>

          {/* Footer */}
          <footer className="border-t bg-gray-50">
            <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
              <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
                <div>
                  <h3 className="text-sm font-semibold text-gray-900">About</h3>
                  <p className="mt-4 text-sm text-gray-600">
                    {SITE_NAME} - Your premium e-commerce store
                  </p>
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-gray-900">Links</h3>
                  <ul className="mt-4 space-y-2">
                    <li><a href="/" className="text-sm text-gray-600 hover:text-gray-900">Home</a></li>
                    <li><a href="/" className="text-sm text-gray-600 hover:text-gray-900">Products</a></li>
                  </ul>
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-gray-900">Contact</h3>
                  <p className="mt-4 text-sm text-gray-600">
                    Email: contact@{SITE_NAME?.toLowerCase()}.com
                  </p>
                </div>
              </div>
              <div className="mt-8 border-t border-gray-200 pt-8">
                <p className="text-center text-sm text-gray-600">
                  © {new Date().getFullYear()} {SITE_NAME}. All rights reserved.
                </p>
              </div>
            </div>
          </footer>
        </div>
        <Toaster closeButton />
        <WelcomeToast />
      </CartProvider>
    </ThemeProvider>
  );
}

