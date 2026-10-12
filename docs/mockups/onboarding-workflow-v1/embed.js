(() => {
 'use strict';
 const key='travary-onboarding-workflow-v1';
 const state=()=>{try{return JSON.parse(sessionStorage.getItem(key)||'{}');}catch{return {};}};
 const emit=(action,data={})=>parent.postMessage({channel:'travary-workflow-v1',action,data},location.origin);
 window.workflow={state,emit,step:(step,message)=>emit('step',{step,message}),draft:data=>emit('draft',data)};
 window.addEventListener('message',event=>{if(event.origin===location.origin&&event.source===parent&&event.data?.channel==='travary-workflow-config')window.dispatchEvent(new CustomEvent('workflow-stills',{detail:event.data.stills===true}));});
 document.addEventListener('DOMContentLoaded',()=>{
  const phone=document.querySelector('.screen,.tf-phone,.phone');
  const measure=()=>emit('height',{height:phone.getBoundingClientRect().height});
  new ResizeObserver(measure).observe(phone);measure();
 });
})();
