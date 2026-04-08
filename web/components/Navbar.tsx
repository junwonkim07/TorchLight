'use client'

import Link from 'next/link'
import { useSession, signOut, signIn } from 'next-auth/react'

export default function Navbar() {
  const { data: session } = useSession()

  return (
    <nav className="border-b border-zinc-200 bg-white px-4 py-3 dark:border-zinc-800 dark:bg-black">
      <div className="mx-auto flex max-w-7xl items-center justify-between">
        <Link href="/" className="text-xl font-bold text-black dark:text-white">
          V2Gravity
        </Link>
        <div className="flex items-center gap-6 text-sm font-medium">
          <Link href="/pricing" className="text-zinc-600 hover:text-black dark:text-zinc-400 dark:hover:text-white">
            Pricing
          </Link>
          <Link href="/board" className="text-zinc-600 hover:text-black dark:text-zinc-400 dark:hover:text-white">
            Board
          </Link>
          {session ? (
            <>
              <Link href="/dashboard" className="text-zinc-600 hover:text-black dark:text-zinc-400 dark:hover:text-white">
                Dashboard
              </Link>
              <button
                onClick={() => signOut()}
                className="rounded-full bg-zinc-900 px-4 py-2 text-white hover:bg-zinc-800 dark:bg-white dark:text-black dark:hover:bg-zinc-200"
              >
                Sign Out
              </button>
            </>
          ) : (
            <button
              onClick={() => signIn()}
              className="rounded-full bg-zinc-900 px-4 py-2 text-white hover:bg-zinc-800 dark:bg-white dark:text-black dark:hover:bg-zinc-200"
            >
              Sign In
            </button>
          )}
        </div>
      </div>
    </nav>
  )
}
