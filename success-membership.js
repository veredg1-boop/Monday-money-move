(() => {
  'use strict';
  const membership = window.MMMMembership, element = id => document.getElementById(id);
  const url = new URL(location.href);
  let reference = url.searchParams.get('session_id') || new URLSearchParams(url.hash.slice(1)).get('access') || '';
  history.replaceState(null,'',url.pathname);
  if (!reference) { try { reference = sessionStorage.getItem('mmmPendingCheckout') || membership.reference; } catch { reference=membership.reference; } }
  if(membership.validReference(reference)) { try { sessionStorage.setItem('mmmPendingCheckout',reference); } catch {} }
  async function check() {
    element('retryMembership').hidden=true;
    element('successTitle').textContent='Checking your membership…';
    element('successMessage').textContent='Confirming your access with Stripe.';
    const ok=await membership.verify(reference);
    element('openMembership').hidden=!ok;
    element('accessRecovery').hidden=!ok;
    element('retryMembership').hidden=ok || !membership.validReference(reference);
    element('successTitle').textContent=ok?'Your membership is ready':membership.state==='unavailable'?'We could not check your membership yet':'Membership not confirmed';
    element('successMessage').textContent=ok?'Welcome. Save your private access link below, then open Monday Money Move.':membership.validReference(reference)?'Please check again in a moment. If this continues, contact support using your checkout email. Do not start another subscription.':'Open the private access link saved after checkout, or contact support using your checkout email. Do not start another subscription.';
  }
  element('retryMembership').onclick=check;
  element('saveAccess').onclick=() => {
    if(!membership.active()) { check(); return; }
    const link=new URL('success.html',location.href);link.hash='access='+reference;
    const blob=new Blob(['Monday Money Move — PRIVATE membership access\nKeep this link safe. Anyone with it can access your membership.\n\n'+link.href+'\n\nYour spending records stay in the browser where you entered them.\n'],{type:'text/plain;charset=utf-8'});
    const file=URL.createObjectURL(blob),a=document.createElement('a');a.href=file;a.download='Monday-Money-Move-private-access.txt';a.click();setTimeout(()=>URL.revokeObjectURL(file),1000);
  };
  check();
})();
