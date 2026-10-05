(() => {
  'use strict';
  const element=id=>document.getElementById(id),config=window.MMMRecoveryConfig;
  let busy=false,endpoint;
  try {
    endpoint=new URL(config?.endpoint);
    if(config?.enabled!==true||endpoint.href!=='https://qystudxmmolypdfpnzep.supabase.co/functions/v1/membership-recovery/recover'||location.origin!=='https://veredg1-boop.github.io')throw Error();
  }catch{element('recoveryUnavailable').hidden=false;return;}
  element('requestLink').hidden=false;
  element('requestLink').addEventListener('submit',async event=>{
    event.preventDefault();if(busy)return;busy=true;element('sendLink').disabled=true;
    element('recoveryStatus').textContent='Sending your sign-in link…';
    try {
      const response=await fetch(endpoint.href,{method:'POST',headers:{'Content-Type':'application/json'},
        body:JSON.stringify({action:'request',email:element('checkoutEmail').value.trim().toLowerCase()}),
        credentials:'omit',cache:'no-store',signal:AbortSignal.timeout(20000)});
      const result=await response.json();if(!response.ok)throw Error(result.error||'Please try again.');
      element('recoveryStatus').textContent='Check your inbox and spam folder. Open the sign-in link within 10 minutes.';
    }catch(error){element('recoveryStatus').textContent=error.name==='TimeoutError'?'The request took too long. Please try again.':error.message;}
    finally{busy=false;element('sendLink').disabled=false;}
  });
})();
