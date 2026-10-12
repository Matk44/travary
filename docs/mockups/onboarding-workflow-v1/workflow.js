(() => {
 'use strict';
 const key='travary-onboarding-workflow-v1', introKey='travary-workflow-intro-v1';
 let frame=document.getElementById('scene');
 const status=document.getElementById('status');
 const steps=['destination','dates','booking','proof','account','passes','holiday'];
 const fresh=()=>({destination:'Bali',departure:'',returnDate:'',flexible:false,booking:null,view:'journey',step:'destination',stills:false,width:430,purchaseResult:'success',authResult:'success',accountMethod:null,accountView:null,accountCompleted:false,selectedOffer:'holiday',choice:null,exampleDate:'2026-11-08'});
 let state=fresh();
 try{const saved=JSON.parse(sessionStorage.getItem(key)||'null');if(saved&&['journey','folio','handoff'].includes(saved.view)&&steps.includes(saved.step))state={...state,...saved};}catch{}
 function persist(){sessionStorage.setItem(key,JSON.stringify(state));}
 function finishMessage(){
  const choice=state.choice==='free'?'Finished with free.':`Finished with a simulated ${state.choice==='holiday'?'Holiday':'Annual'} Pass. Nothing was charged.`;
  return choice+' '+(state.booking?'Your same example booking stays in the holiday.':'Add your first booking when you are ready.');
 }
 function progress(){
  const current=steps.indexOf(state.step);
  document.querySelectorAll('[data-step]').forEach(e=>{
   const index=steps.indexOf(e.dataset.step),postponed=e.dataset.step==='proof'&&!state.booking&&current>index;
   e.classList.toggle('done',index<current);e.classList.toggle('skipped',postponed);
   if(e.dataset.step==='proof')e.textContent=postponed?'First booking postponed':'Travi looks after your booking';
   if(index===current)e.setAttribute('aria-current','step');else e.removeAttribute('aria-current');
  });
  document.getElementById('back').disabled=state.view==='journey';
  document.getElementById('stills').checked=state.stills;
  document.getElementById('preview-size').value=String(state.width);
  document.querySelector('.preview').style.width='min('+state.width+'px,100%)';
  document.getElementById('purchase-result').value=state.purchaseResult;
  document.getElementById('auth-result').value=state.authResult;
 }
 function open(view){
  state.view=view;persist();progress();
  // A fresh frame disposes the previous scene's media and pending work.
  const next=document.createElement('iframe');next.id='scene';next.title='Travary onboarding';next.allow='autoplay';next.style.height=frame.style.height;
  next.addEventListener('load',()=>{if(frame===next)sendConfig();});
  const previous=frame;frame=next;
  next.src={journey:'journey.html',folio:'folio.html',handoff:'handoff.html'}[view];
  previous.replaceWith(next);
 }
 function sendConfig(){frame.contentWindow?.postMessage({channel:'travary-workflow-config',stills:state.stills},location.origin);}
 window.addEventListener('message',event=>{
  if(event.origin!==location.origin||event.source!==frame.contentWindow||event.data?.channel!=='travary-workflow-v1')return;
  const {action,data={}}=event.data;
  if(action==='height'){if(Number.isFinite(data.height))frame.style.height=Math.ceil(Math.max(400,Math.min(2000,data.height)))+'px';return;}
  if(action==='step'){if(steps.includes(data.step)){state.step=data.step;if(data.step!=='holiday')state.choice=null;}if(data.message)status.textContent=data.step==='holiday'&&state.choice?finishMessage():data.message;}
  if(action==='draft'){state={...state,...data};}
  if(action==='booking'){state.booking=data;state.step='proof';state.choice=null;open('handoff');return;}
  if(action==='open-booking'){state={...state,...data,step:'booking',choice:null};open('folio');return;}
  if(action==='later'){state.booking=null;state.step='account';state.accountView='account';state.accountCompleted=false;state.choice=null;open('handoff');return;}
  if(action==='back-booking'){state.step='booking';state.choice=null;open('folio');return;}
  if(action==='complete'){state.step='holiday';state.choice=data.choice;status.textContent=finishMessage();}
  persist();progress();
 });
 document.getElementById('restart').addEventListener('click',()=>{state=fresh();sessionStorage.removeItem(introKey);status.textContent='Start by choosing your destination.';open('journey');});
 document.getElementById('back').addEventListener('click',()=>{state.step='dates';state.choice=null;status.textContent='Your holiday setup is kept. Change its dates or continue.';open('journey');});
 document.getElementById('stills').addEventListener('change',event=>{state.stills=event.target.checked;persist();sendConfig();});
 document.getElementById('purchase-result').addEventListener('change',event=>{state.purchaseResult=event.target.value;persist();});
 document.getElementById('auth-result').addEventListener('change',event=>{state.authResult=event.target.value;persist();});
 document.getElementById('preview-size').addEventListener('change',event=>{state.width=Number(event.target.value);persist();progress();});
 if(state.step==='holiday')status.textContent='Your completed example holiday has been restored. Restart to try another route.';
 open(state.view);
})();
