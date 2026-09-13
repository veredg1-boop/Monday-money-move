/* Stripe credentials stay on the server. Only a private checkout reference is stored here. */
(() => {
  'use strict';
  const endpoint = 'https://qystudxmmolypdfpnzep.supabase.co/functions/v1/membership-status';
  const storageKey = 'mmmVerifiedCheckoutSession';
  const validReference = value => typeof value === 'string' && /^cs_live_[A-Za-z0-9]{24,220}$/.test(value);
  let reference = '', entitlement = null, checkedAt = 0, state = 'checking', pending = null;
  try { reference = localStorage.getItem(storageKey) || ''; } catch {}
  const active = () => !!entitlement && Date.now() - checkedAt < 90000 && entitlement.valid_until * 1000 > Date.now();
  const notify = () => window.dispatchEvent(new CustomEvent('mmm-membership', {detail:{active:active(),state}}));
  async function verify(candidate = reference) {
    if (pending) return pending;
    if (!validReference(candidate)) { entitlement = null; state = 'inactive'; notify(); return false; }
    reference = candidate;
    pending = (async () => {
      const controller = new AbortController(), timeout = setTimeout(() => controller.abort(), 12000);
      state = 'checking'; notify();
      try {
        const response = await fetch(endpoint, {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({checkout_session_id:reference}),credentials:'omit',cache:'no-store',signal:controller.signal});
        if (!response.ok) throw Error('Verification unavailable');
        const result = await response.json();
        entitlement = result.active === true && ['active','trialing'].includes(result.status) && Number.isFinite(result.valid_until) && result.valid_until * 1000 > Date.now() ? result : null;
        checkedAt = Date.now(); state = entitlement ? 'active' : 'inactive';
        if (entitlement) { try { localStorage.setItem(storageKey,reference); } catch {} }
      } catch { entitlement = null; state = 'unavailable'; }
      finally { clearTimeout(timeout); notify(); }
      return active();
    })();
    try { return await pending; } finally { pending = null; }
  }
  window.MMMMembership = Object.freeze({active,verify,validReference,get state(){return active()?'active':state;},get reference(){return reference;}});
  // The return page must verify the reference from checkout before checking saved access.
  if (!location.pathname.endsWith('/success.html')) verify();
  setInterval(() => { if(validReference(reference)) verify(); else notify(); },60000);
  window.addEventListener('focus',() => { if(Date.now()-checkedAt>30000) verify(); });
})();
