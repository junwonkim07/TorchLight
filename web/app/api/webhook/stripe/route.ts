import { NextResponse } from 'next/server'
import { stripe } from '@/lib/stripe'
import { createMarzbanUser } from '@/lib/marzban'
import { supabase } from '@/lib/supabase'

export async function POST(req: Request) {
  const body = await req.text()
  const signature = req.headers.get('stripe-signature') as string

  let event

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch (err: any) {
    return new NextResponse(`Webhook Error: ${err.message}`, { status: 400 })
  }

  const session = event.data.object as any

  if (event.type === 'checkout.session.completed') {
    const userEmail = session.customer_details.email
    const priceId = session.line_items?.data[0]?.price.id
    
    // Determine plan based on priceId (you should map these in your config)
    let plan: '1month' | '3month' | '1year' = '1month'
    if (priceId === process.env.STRIPE_PRICE_ID_3MONTH) plan = '3month'
    if (priceId === process.env.STRIPE_PRICE_ID_1YEAR) plan = '1year'

    try {
      // 1. Create/Update user in Supabase with subscription info
      const { data: user, error: userError } = await supabase
        .from('profiles')
        .update({ 
          subscription_status: 'active',
          stripe_customer_id: session.customer,
          plan: plan
        })
        .eq('email', userEmail)
        .select()
        .single()

      if (userError) throw userError

      // 2. Create user in Marzban
      // Use email as username (sanitized)
      const marzbanUsername = userEmail.replace(/[@.]/g, '_')
      await createMarzbanUser(marzbanUsername, plan)

      console.log(`Successfully processed subscription for ${userEmail}`)
    } catch (error) {
      console.error('Error processing checkout.session.completed:', error)
      return new NextResponse('Internal Error', { status: 500 })
    }
  }

  return new NextResponse(null, { status: 200 })
}
