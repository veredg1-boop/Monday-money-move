import test from 'node:test';
import assert from 'node:assert/strict';
import { entitlement, makeHandler, PRICE_ID, PAYMENT_LINK_ID, SITE_ORIGIN } from '../supabase/functions/membership-status/handler.mjs';
const now = 1800000000000;
const session = () => ({ livemode: true, status: 'complete', mode: 'subscription',
  payment_link: PAYMENT_LINK_ID, customer: 'customer-fixture',
  subscription: { livemode: true, customer: 'customer-fixture', status: 'trialing', trial_end: now / 1000 + 3600,
    items: { data: [{ quantity: 1, current_period_end: now / 1000 + 3600,
      price: { id: PRICE_ID, unit_amount: 999, currency: 'usd', recurring: { interval: 'month', interval_count: 1 } } }] } } });
test('verified trial and paid renewal grant access until their actual end', () => {
  const s = session(); assert.equal(entitlement(s, now).active, true);
  s.subscription.status = 'active'; s.subscription.latest_invoice = { status: 'paid' };
  assert.equal(entitlement(s, now).active, true);
  s.subscription.cancel_at_period_end = true;
  assert.equal(entitlement(s, now).active, true);
  assert.equal(entitlement(s, now + 3600001).active, false);
});
test('unpaid, canceled, test-mode, wrong-product and unfinished sessions fail closed', () => {
  for (const mutate of [s=>s.status='open', s=>s.livemode=false,
    s=>s.payment_link='another-link', s=>s.subscription.status='canceled',
    s=>s.subscription.status='past_due', s=>s.subscription.status='active',
    s=>s.subscription.customer='another-customer',
    s=>s.subscription.items.data[0].price.unit_amount=995,
    s=>s.subscription.items.data[0].price.id='another-price',
    s=>s.subscription.pause_collection={behavior:'void'}]) {
    const s=session();mutate(s);assert.equal(entitlement(s, now).active,false);
  }
});
const request=(id='cs_live_'+'a'.repeat(50), origin=SITE_ORIGIN)=>new Request('https://example.test/status',{
  method:'POST',headers:{origin,'content-type':'application/json'},body:JSON.stringify({checkout_session_id:id})});
test('missing secret, bad origin and fabricated IDs cannot enable membership',async()=>{
  let called=false;
  const handler=makeHandler({getKey:()=>undefined,fetchStripe:()=>{called=true;},now:()=>now});
  assert.equal((await handler(request())).status,503);
  assert.equal((await handler(request(undefined,'https://untrusted.example'))).status,403);
  assert.equal(called,false);
  const configured=makeHandler({getKey:()=>['rk','live','testfixture'].join('_'),fetchStripe:()=>{called=true;},now:()=>now});
  assert.equal((await configured(request('true'))).status,400);
  assert.equal(called,false);
});
test('only minimal status leaves server; Stripe errors never leak response or credentials',async()=>{
  const handler=makeHandler({getKey:()=>['rk','live','testfixture'].join('_'),now:()=>now,
    fetchStripe:async()=>new Response(JSON.stringify({...session(),customer_details:{email:'private@example.test'}}))});
  const body=await (await handler(request())).json();
  assert.deepEqual(Object.keys(body).sort(),['active','cancel_at_period_end','status','valid_until']);
  const failing=makeHandler({getKey:()=>['rk','live','testfixture'].join('_'),now:()=>now,
    fetchStripe:async()=>new Response('secret error text',{status:403})});
  assert.equal((await failing(request())).status,503);
  assert.equal((await (await failing(request())).text()).includes('secret error text'),false);
});
