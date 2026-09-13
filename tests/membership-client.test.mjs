import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import fs from 'node:fs';
import {makeHandler,SITE_ORIGIN,PRICE_ID,PAYMENT_LINK_ID} from '../supabase/functions/membership-status/handler.mjs';
const source=fs.readFileSync(new URL('../membership.js',import.meta.url),'utf8');
const reference='cs_live_'+'a'.repeat(50);
function client(fetch, stored={}) {
  const values=new Map(Object.entries(stored)),listeners={};
  const context={window:{dispatchEvent(){},addEventListener(n,f){listeners[n]=f;}},CustomEvent:class {},localStorage:{getItem:k=>values.get(k),setItem:(k,v)=>values.set(k,v)},location:{pathname:'/success.html'},Date,AbortController,setTimeout,clearTimeout,setInterval(){},fetch};
  vm.runInNewContext(source,context);return {api:context.window.MMMMembership,values};
}
test('legacy local flags and invalid references cannot activate membership',async()=>{
  let calls=0;const {api}=client(()=>{calls++;},{mmmMember:'true',mmmPaid:'1'});
  assert.equal(api.active(),false);assert.equal(await api.verify('true'),false);assert.equal(calls,0);
});
test('client and deployed handler agree on request contract and verified trial',async()=>{
  const until=Math.floor(Date.now()/1000)+3600;
  const handler=makeHandler({getKey:()=>['rk','live','fixture'].join('_'),fetchStripe:async()=>Response.json({livemode:true,status:'complete',mode:'subscription',payment_link:PAYMENT_LINK_ID,customer:'fixture',subscription:{livemode:true,customer:'fixture',status:'trialing',trial_end:until,items:{data:[{quantity:1,price:{id:PRICE_ID,unit_amount:999,currency:'usd',recurring:{interval:'month',interval_count:1}}}]}}})});
  const {api,values}=client((url,options)=>handler(new Request(url,{...options,headers:{...options.headers,origin:SITE_ORIGIN}})));
  assert.equal(await api.verify(reference),true);assert.equal(api.active(),true);assert.equal(values.get('mmmVerifiedCheckoutSession'),reference);
});
test('saved references require re-verification and connection failures revoke access',async()=>{
  let fails=false;const {api}=client(async()=>{if(fails)throw Error();return Response.json({active:true,status:'active',valid_until:Date.now()/1000+3600});},{mmmVerifiedCheckoutSession:reference});
  assert.equal(api.active(),false);assert.equal(await api.verify(),true);fails=true;assert.equal(await api.verify(),false);assert.equal(api.active(),false);
});
test('unpaid and expired responses cannot grant access',async()=>{
  for(const result of [{active:false},{active:true,status:'trialing',valid_until:1},{active:true,status:'past_due',valid_until:Date.now()/1000+3600}]){
    const {api}=client(async()=>Response.json(result));assert.equal(await api.verify(reference),false);
  }
});
