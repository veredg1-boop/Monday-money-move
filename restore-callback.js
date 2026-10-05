(async () => {
  'use strict';
  // Run before loading other resources. Never persist Auth tokens or retain the
  // refresh token, and remove both query and fragment from the browser history.
  let fragment=new URLSearchParams(location.hash.slice(1));
  let token=fragment.get('access_token')||'';
  const hasError=fragment.has('error');
  fragment=null;
  history.replaceState(null,'',location.pathname);
  const show=message=>{
    const render=()=>{document.getElementById('callbackStatus').textContent=message;};
    if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',render,{once:true});else render();
  };
  try {
    if(location.origin!=='https://veredg1-boop.github.io'||location.pathname!=='/Monday-money-move/restore-callback.html'||hasError||!token)throw Error('This link is invalid or expired. Please request another.');
    const pending=fetch('https://qystudxmmolypdfpnzep.supabase.co/functions/v1/membership-recovery/restore-session',{
      method:'POST',headers:{Authorization:'Bearer '+token},credentials:'omit',cache:'no-store',
      referrerPolicy:'no-referrer',signal:AbortSignal.timeout(45000)});
    token='';
    const response=await pending,result=await response.json();
    if(!response.ok)throw Error(result.error||'Unable to verify this link. Please request another.');
    if(result.active===true&&/^cs_live_[A-Za-z0-9]{24,220}$/.test(result.checkout_session_id||'')){
      // The return page independently checks the current Stripe subscription.
      location.replace('success.html#access='+result.checkout_session_id);return;
    }
    show('No current membership could be restored. Contact support; do not subscribe again.');
  }catch(error){show(error.name==='TimeoutError'?'The check timed out. Please request another link.':error.message);}
  finally{token='';}
})();
