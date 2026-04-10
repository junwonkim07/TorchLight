import ErrorNoKeys from '@/components/react-bricks/error-no-keys';
import ErrorNoPage from '@/components/react-bricks/error-no-page';
import config from '@/react-bricks/config';
import type { Metadata } from 'next';
import {
    JsonLd,
    PageViewer,
    cleanPage,
    fetchPage,
    getBricks,
    getMetadata,
    types
} from 'react-bricks/rsc';
import { ClickToEdit } from 'react-bricks/rsc/client';

const getData = async (
  slug?: string[]
): Promise<{
  page: types.Page | null;
  errorNoKeys: boolean;
  errorPage: boolean;
}> => {
  let errorPage = false;

  if (!config.apiKey) {
    return {
      page: null,
      errorNoKeys: true,
      errorPage
    };
  }

  const cleanSlug = !slug || slug.length === 0 ? '/' : slug.join('/');

  const page = await fetchPage({
    slug: cleanSlug,
    language: 'en',
    config,
    fetchOptions: {
      next: { revalidate: parseInt(process.env.REACT_BRICKS_REVALIDATE || '3', 10) }
    }
  }).catch(() => {
    errorPage = true;
    return null;
  });

  return {
    page,
    errorNoKeys: false,
    errorPage
  };
};

export async function generateMetadata({
  params
}: {
  params: { page?: string[] };
}): Promise<Metadata> {
  const { page } = await getData(params.page);
  if (!page?.meta) {
    return {};
  }

  return getMetadata(page);
}

export default async function Page({ params }: { params: { page?: string[] } }) {
  const { page, errorNoKeys, errorPage } = await getData(params.page);

  const bricks = getBricks();
  const pageOk = page ? cleanPage(page, config.pageTypes || [], bricks) : null;

  return (
    <>
      {page?.meta && <JsonLd page={page} />}
      {pageOk && !errorPage && !errorNoKeys && <PageViewer page={pageOk} main />}
      {errorNoKeys && <ErrorNoKeys />}
      {errorPage && <ErrorNoPage />}
      {pageOk && config && (
        <ClickToEdit
          pageId={pageOk.id}
          language={pageOk.language}
          editorPath={config.editorPath || '/admin/editor'}
          clickToEditSide={config.clickToEditSide}
        />
      )}
    </>
  );
}

