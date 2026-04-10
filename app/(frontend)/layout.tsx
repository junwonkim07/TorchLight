import config from '@/react-bricks/config';
import { CartProvider } from 'components/cart/cart-context';
import ErrorNoFooter from 'components/react-bricks/error-no-footer';
import ErrorNoHeader from 'components/react-bricks/error-no-header';
import ErrorNoKeys from 'components/react-bricks/error-no-keys';
import PageLayout from 'components/react-bricks/layout';
import ReactBricksApp from 'components/react-bricks/react-bricks-app';
import { ThemeProvider } from 'components/react-bricks/theme-provider';
import { WelcomeToast } from 'components/welcome-toast';
import { getCart } from 'lib/medusa';
import { ensureStartsWith } from 'lib/utils';
import { cookies } from 'next/headers';
import { ReactNode } from 'react';
import { PageViewer, cleanPage, fetchPage, getBricks, register, types } from 'react-bricks/rsc';
import { Toaster } from 'sonner';
import '../globals.css';
import './styles.css';

const { TWITTER_CREATOR, TWITTER_SITE, SITE_NAME } = process.env;
const baseUrl = process.env.NEXT_PUBLIC_VERCEL_URL
  ? `https://${process.env.NEXT_PUBLIC_VERCEL_URL}`
  : 'http://localhost:3000';
const twitterCreator = TWITTER_CREATOR ? ensureStartsWith(TWITTER_CREATOR, '@') : undefined;
const twitterSite = TWITTER_SITE ? ensureStartsWith(TWITTER_SITE, 'https://') : undefined;

register(config);

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

const getData = async (): Promise<{
  header: types.Page | null;
  footer: types.Page | null;
  errorNoKeys: boolean;
  errorHeader: boolean;
  errorFooter: boolean;
}> => {
  let errorNoKeys = false;
  let errorHeader = false;
  let errorFooter = false;

  if (!config.apiKey) {
    errorNoKeys = true;

    return {
      header: null,
      footer: null,
      errorNoKeys,
      errorHeader,
      errorFooter
    };
  }

  const [header, footer] = await Promise.all([
    fetchPage({
      slug: 'header',
      language: 'en',
      config,
      fetchOptions: {
        next: { revalidate: parseInt(process.env.REACT_BRICKS_REVALIDATE || '3', 10) }
      }
    }).catch(() => {
      errorHeader = true;
      return null;
    }),
    fetchPage({
      slug: 'footer',
      language: 'en',
      config,
      fetchOptions: {
        next: { revalidate: parseInt(process.env.REACT_BRICKS_REVALIDATE || '3', 10) }
      }
    }).catch(() => {
      errorFooter = true;
      return null;
    })
  ]);

  return {
    header,
    footer,
    errorNoKeys,
    errorHeader,
    errorFooter
  };
};

export default async function RootLayout({ children }: { children: ReactNode }) {
  const cartId = cookies().get('cartId')?.value;
  const cart = getCart(cartId);
  const { header, footer, errorNoKeys, errorHeader, errorFooter } = await getData();
  const bricks = getBricks();
  const headerOk = header ? cleanPage(header, config.pageTypes || [], bricks) : null;
  const footerOk = footer ? cleanPage(footer, config.pageTypes || [], bricks) : null;

  return (
    <ThemeProvider attribute="class" storageKey="color-mode" defaultTheme="system" enableSystem>
      <CartProvider cartPromise={cart}>
        <ReactBricksApp>
          <PageLayout>
            {!errorNoKeys && (
              <>
                {headerOk && !errorHeader ? <PageViewer page={headerOk} main={false} /> : <ErrorNoHeader />}
                {children}
                {footerOk && !errorFooter ? <PageViewer page={footerOk} main={false} /> : <ErrorNoFooter />}
              </>
            )}
            {errorNoKeys && <ErrorNoKeys />}
          </PageLayout>
        </ReactBricksApp>
        <Toaster closeButton />
        <WelcomeToast />
      </CartProvider>
    </ThemeProvider>
  );
}

