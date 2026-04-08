import Stripe from 'stripe'

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-01-27-ac', // Use the latest API version or match your stripe version
  typescript: true,
})

export async function createCheckoutSession(customerId: string, priceId: string, userEmail: string) {
  const session = await stripe.checkout.sessions.create({
    customer: customerId,
    customer_email: customerId ? undefined : userEmail,
    line_items: [
      {
        price: priceId,
        quantity: 1,
      },
    ],
    mode: 'subscription',
    success_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard?success=true`,
    cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/pricing?canceled=true`,
    subscription_data: {
      metadata: {
        user_email: userEmail,
      },
    },
  })

  return session
}
