import { makeHandler } from './handler.mjs';

// Store this read-only restricted key in Supabase Edge Function Secrets.
// No Stripe key is ever sent to the website or committed to source control.
Deno.serve(makeHandler({
  getKey: () => Deno.env.get('MMM_STRIPE_READ_KEY') || Deno.env.get('STRIPE_SECRET_KEY'),
}));
