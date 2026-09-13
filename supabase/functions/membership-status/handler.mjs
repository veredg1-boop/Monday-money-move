// Read-only verification. The unguessable checkout session ID is a private
// bearer credential; never log it or return Stripe customer/payment details.
export const SITE_ORIGIN = 'https://veredg1-boop.github.io';
export const PRICE_ID = 'price_1UAfvC51f28hskX08LlxMY49';
export const PAYMENT_LINK_ID = 'plink_1UAg0C51f28hskX0t55IcdFp';

export function entitlement(session, now = Date.now()) {
  const denied = { active: false };
  const sub = session?.subscription;
  if (session?.livemode !== true || session.status !== 'complete' ||
      session.mode !== 'subscription' || session.payment_link !== PAYMENT_LINK_ID ||
      !sub || typeof sub !== 'object' || sub.livemode !== true ||
      sub.customer !== session.customer || sub.pause_collection) return denied;
  const items = sub.items?.data;
  if (!Array.isArray(items) || items.length !== 1) return denied;
  const item = items[0], price = item.price;
  if (item.quantity !== 1 || price?.id !== PRICE_ID || price.unit_amount !== 999 ||
      price.currency !== 'usd' || price.recurring?.interval !== 'month' ||
      price.recurring.interval_count !== 1) return denied;
  if (!['trialing', 'active'].includes(sub.status)) return denied;
  if (sub.status === 'active' && sub.latest_invoice?.status !== 'paid') return denied;
  const until = sub.status === 'trialing' ? sub.trial_end : item.current_period_end;
  if (!Number.isFinite(until) || until * 1000 <= now) return denied;
  return { active: true, status: sub.status, valid_until: until,
    cancel_at_period_end: sub.cancel_at_period_end === true };
}

export function makeHandler({ getKey, fetchStripe = fetch, now = Date.now }) {
  const attempts = new Map();
  return async function handler(req) {
    const origin = req.headers.get('origin');
    const headers = { 'Content-Type': 'application/json', 'Cache-Control': 'no-store',
      'Vary': 'Origin', 'Access-Control-Allow-Origin': SITE_ORIGIN,
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'content-type', 'X-Content-Type-Options': 'nosniff' };
    const reply = (body, status = 200) => new Response(JSON.stringify(body), { status, headers });
    if (origin !== SITE_ORIGIN) return reply({ error: 'Origin not allowed' }, 403);
    if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers });
    if (req.method !== 'POST') return reply({ error: 'Use POST' }, 405);
    const key = getKey();
    if (!key || !/^(rk|sk)_live_/.test(key)) return reply({ error: 'Membership verification is not configured' }, 503);
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0] || 'unknown';
    const minute = Math.floor(now() / 60000);
    const recent = attempts.get(ip);
    const count = recent?.minute === minute ? recent.count + 1 : 1;
    // Bounded per-instance abuse limit; no IP data leaves this process.
    if (attempts.size > 2000) attempts.clear();
    attempts.set(ip, { minute, count });
    if (count > 20) return reply({ error: 'Please try again shortly' }, 429);
    try {
      if (!req.headers.get('content-type')?.startsWith('application/json')) return reply({ error: 'Use JSON' }, 415);
      if (Number(req.headers.get('content-length')) > 512) return reply({ error: 'Request too large' }, 413);
      const raw = await req.text();
      if (raw.length > 512) return reply({ error: 'Request too large' }, 413);
      const { checkout_session_id: id } = JSON.parse(raw);
      if (typeof id !== 'string' || !/^cs_live_[A-Za-z0-9]{24,220}$/.test(id)) return reply({ active: false }, 400);
      const url = new URL('https://api.stripe.com/v1/checkout/sessions/' + id);
      url.searchParams.append('expand[]', 'subscription.latest_invoice');
      const response = await fetchStripe(url, { headers: {
        Authorization: 'Bearer ' + key, 'Stripe-Version': '2026-07-29.dahlia'
      }, signal: AbortSignal.timeout(10000) });
      if (response.status === 404) return reply({ active: false });
      if (!response.ok) return reply({ error: 'Could not verify membership. Please try again.' }, 503);
      return reply(entitlement(await response.json(), now()));
    } catch {
      return reply({ error: 'Could not verify membership. Please try again.' }, 503);
    }
  };
}
