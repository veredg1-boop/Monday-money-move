(() => {
  if(window.MMMRecoveryConfig?.enabled===true) {
    document.querySelectorAll('[data-membership-recovery]').forEach(link=>{link.hidden=false;});
  }
})();
