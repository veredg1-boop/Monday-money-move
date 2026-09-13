(() => {
  'use strict';
  const membership=window.MMMMembership, box=document.getElementById('spendingMembership');
  function update(){
    const ok=membership.active();
    document.getElementById('spendingMembershipText').textContent=ok?'Your membership is active. Your spending records stay on this device.':membership.state==='checking'?'Checking membership… Existing records and exports remain available.':membership.state==='unavailable'?'Membership verification is temporarily unavailable. Reconnect and try again. Your existing records and exports remain available.':'Join to save new expenses, budgets, and weekly moves. Existing records and exports remain available. Already joined? Use your private access link or contact support; do not subscribe again.';
    const link=document.getElementById('spendingJoin');link.textContent=ok?'Manage Membership':'Start 7-Day Free Trial';link.href=ok?'support.html#cancel':'https://buy.stripe.com/eVq28k85t1DA8y08g9ds400';
  }
  function gate(event){if(membership.active())return;event.preventDefault();event.stopImmediatePropagation();update();box.scrollIntoView({behavior:'smooth'});}
  ['expenseForm','budgetForm'].forEach(id=>document.getElementById(id).addEventListener('submit',gate,true));
  ['saveSuggestion','saveImport','readImage','parseText','useExample'].forEach(id=>document.getElementById(id).addEventListener('click',gate,true));
  window.addEventListener('mmm-membership',update);update();
})();
