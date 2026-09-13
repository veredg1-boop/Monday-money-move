/* Navigation and verified membership presentation. */
const menuButton=document.getElementById('menuToggle'),siteMenu=document.getElementById('siteMenu');
menuButton.addEventListener('click',()=>{const open=menuButton.getAttribute('aria-expanded')!=='true';menuButton.setAttribute('aria-expanded',String(open));siteMenu.classList.toggle('is-open',open);});
siteMenu.querySelectorAll('a').forEach(link=>link.addEventListener('click',()=>{siteMenu.classList.remove('is-open');menuButton.setAttribute('aria-expanded','false');}));
const originalRender=render;
render=function(){originalRender();document.getElementById('progressCard').classList.toggle('hidden',!getData().history.length);};
window.addEventListener('mmm-membership',render);
render();
document.getElementById('weeklyCheckInLink').addEventListener('click',event=>{event.preventDefault();startFreeCheckIn();});
