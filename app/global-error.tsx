'use client';

export default function GlobalError({
  error,
  reset
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="en">
      <body className="bg-neutral-50 text-black dark:bg-neutral-900 dark:text-white">
        <div className="mx-auto my-10 flex max-w-xl flex-col rounded-lg border border-neutral-200 bg-white p-8 md:p-12 dark:border-neutral-800 dark:bg-black">
          <h2 className="text-xl font-bold">A critical error occurred</h2>
          <p className="my-2 text-sm text-neutral-600 dark:text-neutral-300">
            {error.message || 'Unexpected application error.'}
          </p>
          <button
            className="mx-auto mt-4 flex w-full items-center justify-center rounded-full bg-blue-600 p-4 tracking-wide text-white hover:opacity-90"
            onClick={() => reset()}
          >
            Reload
          </button>
        </div>
      </body>
    </html>
  );
}