'use strict';
const C=SpendingCore,$=id=>document.getElementById(id),key='mmmSpendingV1';
let data={expenses:[],budgets:{}},editing=null,drafts=[],storageReady=true;
function message(id,text,error=false){$(id).textContent=text;$(id).classList.toggle('error',error);}
try{const raw=localStorage.getItem(key);if(raw){const parsed=JSON.parse(raw);if(!Array.isArray(parsed.expenses)||!parsed.budgets)throw Error();parsed.expenses.forEach(C.validate);data=parsed;}}catch{storageReady=false;message('status','Saved spending could not be read. Nothing has been overwritten. Please export or recover your browser data before adding entries.',true);}
function persist(next){if(!storageReady)throw Error('Saved data needs recovery before new entries can be saved.');try{localStorage.setItem(key,JSON.stringify(next));data=next;}catch{throw Error('This browser could not save your changes. Please allow local storage or export your existing report.');}render();}
function today(){const d=new Date();return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;}
function options(id,values){values.forEach(v=>$(id).add(new Option(v,v)));}
options('category',C.categories);options('budgetCategory',C.categories);options('owner',C.owners);$('month').value=today().slice(0,7);$('date').value=today();
function el(tag,text,className){const e=document.createElement(tag);if(text!==undefined)e.textContent=text;if(className)e.className=className;return e;}
function table(headers,rows){const wrap=el('div',undefined,'table-wrap'),t=el('table'),head=el('thead'),tr=el('tr');headers.forEach(x=>tr.append(el('th',x)));head.append(tr);t.append(head);const b=el('tbody');rows.forEach(row=>{const r=el('tr');row.forEach(x=>{const td=el('td');if(x instanceof Node)td.append(x);else td.textContent=x;r.append(td);});b.append(r);});t.append(b);wrap.append(t);return wrap;}
function render(){const s=C.summary(data,$('month').value,$('ownerFilter').value);$('total').textContent=C.money(s.total);$('change').textContent=s.hasPrior?`${s.total>s.prior?'+':''}${C.money(s.total-s.prior)}`:'—';$('comparison').textContent=s.hasPrior?`Previous month: ${C.money(s.prior)}`:'No recorded expenses last month.';$('recurring').textContent=C.money(s.rows.filter(e=>e.recurring).reduce((a,e)=>a+e.cents,0));const active=s.categories.filter(c=>c.spent||c.budget);$('categorySummary').replaceChildren();if(!active.length)$('categorySummary').append(el('p','Your category totals will appear after you add an expense or budget.','empty'));else $('categorySummary').append(table(['Category','Spent','Budget / remaining'],active.map(c=>{const box=el('div');box.textContent=c.budget?`${C.money(c.budget)} / ${C.money(c.budget-c.spent)} ${c.spent>c.budget?'(over budget)':'left'}`:'No budget set';if(c.budget){const bar=el('div',undefined,'bar'),fill=el('i');fill.style.width=Math.min(100,c.spent/c.budget*100)+'%';bar.append(fill);box.append(bar);if(c.spent>c.budget)box.className='over';}return [c.category,C.money(c.spent),box];})));$('suggestion').textContent=C.suggestion(s);$('saveSuggestion').disabled=!s.rows.length;$('transactions').replaceChildren();if(!s.rows.length)$('transactions').append(el('p','No expenses recorded for this month and filter yet.','empty'));else $('transactions').append(table(['Date','Merchant','Amount','Category','Owner',''],[...s.rows].sort((a,b)=>b.date.localeCompare(a.date)).map(e=>{const button=el('button','Edit','secondary');button.setAttribute('aria-label','Edit '+e.merchant);button.onclick=()=>edit(e);const merchant=el('div',e.merchant);if(e.recurring)merchant.append(el('small',' · Recurring'));return [e.date,merchant,C.money(e.cents),e.category,e.owner,button];})));$('reportPreview').hidden=true;}
function edit(e){editing=e.id;$('date').value=e.date;$('merchant').value=e.merchant;$('amount').value=(e.cents/100).toFixed(2);$('category').value=e.category;$('owner').value=e.owner;$('isRecurring').checked=e.recurring;$('saveExpense').textContent='Save changes';$('cancelEdit').hidden=false;$('add').scrollIntoView({behavior:'smooth'});$('merchant').focus();}
function resetForm(){editing=null;$('expenseForm').reset();$('date').value=today();$('saveExpense').textContent='Save expense';$('cancelEdit').hidden=true;}
$('cancelEdit').onclick=resetForm;
$('expenseForm').onsubmit=e=>{e.preventDefault();try{const item=C.validate({id:editing||crypto.randomUUID(),date:$('date').value,merchant:$('merchant').value,cents:C.cents($('amount').value),category:$('category').value,owner:$('owner').value,recurring:$('isRecurring').checked});const next={...data,expenses:editing?data.expenses.map(x=>x.id===editing?item:x):[...data.expenses,item]};const wasEdit=!!editing;persist(next);$('month').value=item.date.slice(0,7);render();resetForm();message('formMessage',wasEdit?'Expense updated.':'Expense saved on this device.');}catch(err){message('formMessage',err.message,true);}};
$('budgetForm').onsubmit=e=>{e.preventDefault();try{const month=$('month').value;if(!/^\d{4}-\d{2}$/.test(month))throw Error('Choose a month first.');persist({...data,budgets:{...data.budgets,[month]:{...data.budgets[month],[$('budgetCategory').value]:C.cents($('budgetAmount').value)}}});message('budgetMessage','Budget saved for '+month+'.');}catch(err){message('budgetMessage',err.message,true);}};
['month','ownerFilter'].forEach(id=>$(id).onchange=()=>{if(!$('month').value)$('month').value=today().slice(0,7);render();});
$('saveSuggestion').onclick=()=>{try{const raw=localStorage.getItem('mmmData');const moves=raw?JSON.parse(raw):{current:null,history:[]};if(!Array.isArray(moves.history))throw Error('Existing weekly moves could not be read.');const text=$('suggestion').textContent;if(moves.current?.text===text){message('moveMessage','This suggestion is already your current weekly move.');return;}const item={id:Date.now(),date:new Date().toLocaleDateString(),text,complete:false};localStorage.setItem('mmmData',JSON.stringify({...moves,current:item,history:[item,...moves.history]}));message('moveMessage','Saved. Open the weekly check-in to see your move and all previous history.');}catch(err){message('moveMessage','Could not save your move. '+err.message,true);}};
function report(){const s=C.summary(data,$('month').value,$('reportOwner').value),full=$('reportDetail').value==='full';const node=el('div');node.append(el('div','MONDAY MONEY MOVE','eyebrow'),el('h1','Your monthly spending'),el('p',`${$('month').value} · ${$('reportOwner').value} expenses · ${full?'Summary and transactions':'Summary only'}`),el('h2',C.money(s.total)+' recorded'));node.append(table(['Category','Spent','Budget','Remaining'],s.categories.filter(c=>c.spent||c.budget).map(c=>[c.category,C.money(c.spent),c.budget?C.money(c.budget):'—',c.budget?C.money(c.budget-c.spent):'—'])));if(full){node.append(el('h2','Transactions'),table(['Date','Merchant','Amount','Category','Owner'],s.rows.map(e=>[e.date,e.merchant,C.money(e.cents),e.category,e.owner])));}node.append(el('p','USD. Based only on recorded expenses. Budgets are for all owners in this month. Generated '+today()+'.'));return {s,full,node};}
$('previewReport').onclick=()=>{const {node}=report();$('reportPreview').replaceChildren(node);$('reportPreview').hidden=false;};
$('csv').onclick=()=>{const {s,full}=report();const blob=new Blob([`\uFEFF"Month","${$('month').value}"\r\n"Expenses","${$('reportOwner').value}"\r\n"Budget scope","All owners in selected month"\r\n`+C.csv(s,full).replace(/^\uFEFF/,'')],{type:'text/csv;charset=utf-8;'}),url=URL.createObjectURL(blob),a=el('a');a.href=url;a.download=`Monday-Money-Move-${$('month').value}-${$('reportOwner').value}.csv`;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);message('status','Spreadsheet downloaded. You choose whether to share it.');};
$('pdf').onclick=()=>{const {node}=report();$('report').replaceChildren(node);window.print();};
$('readImage').onclick=async()=>{
  const file=$('imageInput').files[0];
  const byExtension={jpg:'image/jpeg',jpeg:'image/jpeg',png:'image/png',heic:'image/heic',heif:'image/heif',pdf:'application/pdf'};
  const supported=Object.values(byExtension);
  const type=file&&(supported.includes(file.type)?file.type:byExtension[file.name.split('.').pop().toLowerCase()]);
  if(!file||!type||file.size>20*1024*1024){message('importMessage','Choose a JPG, PNG, HEIC, or PDF file up to 20 MB.',true);return;}
  $('readImage').disabled=true;$('imageInput').disabled=true;$('parseText').disabled=true;
  // Discard only unsaved draft UI; previously saved expenses are never touched.
  drafts=[];$('drafts').replaceChildren();$('saveImport').hidden=true;$('reviewHeading').hidden=true;
  message('importMessage','Reading your file on this device… Nothing is saved until you approve it.');
  try{
    const text=await window.PrivateImport.read(file,type,status=>message('importMessage',status+' Nothing is saved until you approve it.'));$('importText').value=text;
    $('parseText').onclick();
    if(drafts.length)$('reviewHeading').scrollIntoView({behavior:'smooth',block:'start'});
    else message('importMessage','No transactions were detected. Review the recognized text below, try a clearer file, or select Enter Manually.',true);
  }catch(err){message('importMessage',err.message,true);}
  finally{$('readImage').disabled=false;$('imageInput').disabled=false;$('parseText').disabled=false;}
};
$('useExample').onclick=()=>{
  $('importText').value='09/09/2026 Hair appointment 85.00\n09/10/2026 Grocery store 42.50';
  $('parseText').onclick();
};
$('parseText').onclick=()=>{
  if(!$('importText').value.trim()){
    message('importMessage','Paste transaction lines or select Review example transactions to load the two examples.',true);
    $('importText').focus();return;
  }
  drafts=C.parse($('importText').value,$('month').value);$('drafts').replaceChildren();
  drafts.forEach((d,i)=>{
    const box=el('div',undefined,'draft'),label=el('label',undefined,'check'),check=document.createElement('input');
    check.type='checkbox';check.checked=!data.expenses.some(e=>e.date===d.date&&e.merchant===d.merchant&&e.cents===d.cents);check.id='include-'+i;
    label.append(check,el('span',check.checked?'Include this transaction':'Possible duplicate — not selected'));box.append(label);
    const fields=el('div',undefined,'draft-fields');
    [['date','Date','date',d.date],['merchant','Merchant','text',d.merchant],['amount','Amount (USD)','text',(d.cents/100).toFixed(2)]].forEach(([name,title,type,value])=>{
      const l=el('label',title),input=document.createElement('input');input.type=type;input.value=value;input.id=`draft-${i}-${name}`;l.append(input);fields.append(l);
    });
    [['category','Category',C.categories],['owner','Owner',C.owners]].forEach(([name,title,values])=>{
      const l=el('label',title),input=document.createElement('select');input.id=`draft-${i}-${name}`;values.forEach(v=>input.add(new Option(v,v)));input.value=d[name];l.append(input);fields.append(l);
    });
    box.append(fields);
    const remove=el('button','Remove','secondary');remove.type='button';remove.id='remove-draft-'+i;remove.setAttribute('aria-label','Remove '+d.merchant+' from review');
    remove.onclick=()=>{d.removed=true;check.checked=false;box.hidden=true;if(drafts.every(x=>x.removed)){$('saveImport').hidden=true;$('reviewHeading').hidden=true;}message('importMessage','Transaction removed from this review. Saved expenses are unchanged.');};
    box.append(remove);$('drafts').append(box);
  });
  $('saveImport').hidden=!drafts.length;$('reviewHeading').hidden=!drafts.length;
  const lines=$('importText').value.split(/\r\n?|\n|\u2028|\u2029/).filter(x=>x.trim()).length;
  message('importMessage',`${drafts.length} transaction(s) detected; ${lines-drafts.length} line(s) not recognized. Edit, uncheck, or remove entries below, then select Approve and Save.`,!drafts.length);
};
$('saveImport').onclick=()=>{
  try{
    const chosen=drafts.flatMap((d,i)=>!d.removed&&$('include-'+i).checked?[C.validate({id:crypto.randomUUID(),recurring:d.recurring,date:$(`draft-${i}-date`).value,merchant:$(`draft-${i}-merchant`).value,cents:C.cents($(`draft-${i}-amount`).value),category:$(`draft-${i}-category`).value,owner:$(`draft-${i}-owner`).value})]:[]);
    if(!chosen.length)throw Error('Select at least one reviewed transaction to approve.');
    persist({...data,expenses:[...data.expenses,...chosen]});
    $('drafts').replaceChildren();$('saveImport').hidden=true;$('reviewHeading').hidden=true;drafts=[];
    $('importText').value='';$('imageInput').value='';
    message('importMessage',`${chosen.length} approved transaction(s) saved. Choose their month above to see them.`);
  }catch(err){message('importMessage',err.message,true);}
};

render();
