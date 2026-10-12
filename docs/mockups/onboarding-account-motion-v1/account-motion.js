(() => {
 'use strict';
 const base=new URL('.',document.currentScript.src).href;
 const apple='<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M17.1 12.1c0-2 1.6-3 1.7-3.1-1-1.5-2.6-1.7-3.2-1.7-1.3-.1-2.6.8-3.3.8s-1.8-.8-2.9-.8c-1.5 0-2.9.9-3.7 2.2-1.6 2.7-.4 6.8 1.1 9 .7 1.1 1.6 2.3 2.7 2.2 1.1 0 1.5-.7 2.8-.7s1.6.7 2.8.7c1.2 0 1.9-1.1 2.6-2.2.8-1.3 1.2-2.5 1.2-2.6-.1 0-1.8-.7-1.8-3.8ZM14.7 5.9c.6-.8 1.1-1.8 1-2.9-.9 0-2 .6-2.7 1.4-.6.6-1.1 1.7-1 2.7 1 .1 2-.5 2.7-1.2Z"/></svg>';
 const google='<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#4285F4" d="M22.6 12.3c0-.7-.1-1.4-.2-2.1H12v4h5.9c-.3 1.3-1 2.3-2.2 3v2.6h3.5c2-1.9 3.4-4.4 3.4-7.5Z"/><path fill="#34A853" d="M12 23c3 0 5.6-1 7.4-2.8l-3.5-2.6c-1 .7-2.3 1.1-3.9 1.1-2.9 0-5.3-1.9-6.2-4.5H2.2v2.8C4 20.6 7.7 23 12 23Z"/><path fill="#FBBC05" d="M5.8 14.2c-.2-.7-.4-1.5-.4-2.2s.1-1.5.4-2.2V7H2.2A11 11 0 0 0 1 12c0 1.8.4 3.5 1.2 5l3.6-2.8Z"/><path fill="#EA4335" d="M12 5.3c1.7 0 3.1.6 4.3 1.7l3.2-3.2C17.6 2 15 1 12 1 7.7 1 4 3.4 2.2 7l3.6 2.8C6.7 7.2 9.1 5.3 12 5.3Z"/></svg>';
 const envelope='<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="2" y="4" width="20" height="16" rx="2" fill="none" stroke="currentColor" stroke-width="2"/><path d="m3 6 9 7 9-7" fill="none" stroke="currentColor" stroke-width="2"/></svg>';
 window.TravaryAccountMotion={create(options){
  const {stage,plate,status,still,reduced,onEnter,onPass}=options;
  const heading=document.createElement('header');heading.className='account-heading';heading.hidden=true;
  const controls=document.createElement('div');controls.className='account-controls';controls.hidden=true;
  const signed=document.createElement('p');signed.className='account-signed';signed.hidden=true;signed.innerHTML='<span aria-hidden="true">✓</span>Signed in';
  const skip=document.createElement('button');skip.className='account-skip';skip.hidden=true;skip.textContent='Skip animation';
  const videos=[0,1].map(()=>{const v=document.createElement('video');v.className='account-film';v.muted=true;v.playsInline=true;v.preload='auto';v.setAttribute('aria-hidden','true');stage.append(v);return v;});
  stage.append(heading,controls,signed,skip);
  let mode=null,current=null,token=0,timer=null,fadeTimer=null,method=null;
  const motionOff=()=>still.checked||reduced.matches;
  const asset=name=>new URL(name,base).href;
  const announce=text=>{status.textContent=text;options.onStatus?.(mode,text);};
  const title=(first,accent,subtitle='')=>{heading.replaceChildren();const h=document.createElement('h2'),s=document.createElement('span'),e=document.createElement('em');s.textContent=first;e.textContent=accent;h.append(s,e);heading.append(h);if(subtitle){const p=document.createElement('p');if(subtitle==='Sign in to find your plan on another phone.'){p.append(document.createTextNode('Sign in to find your plan'),document.createElement('br'),document.createTextNode('on another phone.'));}else p.textContent=subtitle;heading.append(p);}heading.hidden=false;};
  function stop(){token++;clearTimeout(timer);clearTimeout(fadeTimer);videos.forEach(v=>{v.pause();v.onended=v.onerror=null;v.classList.remove('active','fading');v.removeAttribute('src');v.load();});current=null;skip.hidden=true;}
  function hide(){heading.hidden=controls.hidden=signed.hidden=true;}
  function fadeToPlate(name){plate.src=asset(name);videos.forEach(v=>{v.pause();v.onended=v.onerror=null;if(v.classList.contains('active')){v.classList.remove('active');v.classList.add('fading');}});fadeTimer=setTimeout(()=>videos.forEach(v=>v.classList.remove('fading')),600);}
  async function play(name,{loop=false,endPlate='account-text-free-v1.png',done=()=>{},progress=()=>{}}={}){
   const guard=++token;clearTimeout(timer);
   if(motionOff()){fadeToPlate(endPlate);done();return;}
   const next=videos.find(v=>v!==current)||videos[0],old=current;
   next.pause();next.onended=next.onerror=null;next.dataset.generation=String(guard);next.classList.remove('active','fading');next.loop=loop;next.src=asset(name+'-v1.mp4');next.load();
   const fail=()=>{if(guard!==token)return;clearTimeout(timer);next.pause();fadeToPlate(endPlate);announce('Video unavailable; settled artwork and all actions remain available.');if(!loop)done();};
   next.onerror=fail;next.ontimeupdate=()=>{if(guard===token)progress(next.currentTime);};next.onended=()=>{if(guard!==token||loop)return;clearTimeout(timer);fadeToPlate(endPlate);done();};
   timer=setTimeout(()=>{if(guard===token&&next.readyState<2)fail();},10000);
   try{await next.play();if(guard!==token){if(next.dataset.generation===String(guard))next.pause();return;}clearTimeout(timer);current=next;next.classList.add('active');if(old){old.classList.remove('active');old.classList.add('fading');setTimeout(()=>{if(current!==old){old.pause();old.classList.remove('fading');}},350);}}catch{fail();}
  }
  function providers(){
   mode='account';stage.dataset.scene='account';stage.classList.remove('account-error-visible');signed.hidden=true;title('Keep your holiday','with you.','Sign in to find your plan on another phone.');
   controls.innerHTML='<button class="account-provider apple" data-account="apple">'+apple+'Continue with Apple</button><button class="account-provider google" data-account="google">'+google+'Continue with Google</button><button class="account-provider email" data-account="email">'+envelope+'Continue with email</button><button class="account-guest" data-account="guest">Continue as a guest</button><p class="account-free">Signing in is free.</p>';
   controls.hidden=false;skip.hidden=true;announce('Travi is waiting. Sign-in controls simulate outcomes; no account is created.');
  }
  function enter({fromProof=true}={}){
   stop();onEnter();hide();providers();
   plate.src=fromProof?options.proofPlate:asset('account-text-free-v1.png');
   if(fromProof&&!motionOff()){skip.hidden=false;play('account-entry',{done:()=>{if(mode==='account'){skip.hidden=true;play('account-idle',{loop:true});}}});}
   else {plate.src=asset('account-text-free-v1.png');play('account-idle',{loop:true});}
  }
  function email(animate=true){
   mode='account-email';stage.dataset.scene=mode;stage.classList.remove('account-error-visible');title('One little link.','And you’re in.','Enter your email to sign in.');signed.hidden=true;
   controls.innerHTML='<form id="account-email-form"><label>Email address<input type="email" name="email" placeholder="you@example.com" autocomplete="email" required></label><button class="ticket-button" type="submit">Email me a sign-in link</button></form><p class="email-copy">No password to remember.</p><button class="account-return" data-account="return">Back to sign-in options</button><button class="account-guest" data-account="guest">Continue as a guest</button>';
   controls.hidden=false;skip.hidden=!animate;announce('Email gesture preview. This form will not send an email.');
   if(animate)play('account-email-gesture',{endPlate:'email-text-free-v1.png',done:()=>{if(mode==='account-email'){skip.hidden=true;play('account-email-idle',{loop:true,endPlate:'email-text-free-v1.png'});}}});
   else {plate.src=asset('email-text-free-v1.png');play('account-email-idle',{loop:true,endPlate:'email-text-free-v1.png'});}
   controls.querySelector('form').addEventListener('submit',event=>{event.preventDefault();sent();});
  }
  function sent(){
   mode='account-email-sent';stage.dataset.scene=mode;title('Check your email.','Almost there.','Open the sign-in link to continue.');
   controls.innerHTML='<p class="email-copy">Preview only: no email has been sent.</p><button class="ticket-button" data-account="demo-link">Open demo sign-in link</button><button class="account-return" data-account="email">Change email address</button><button class="account-guest" data-account="guest">Continue as a guest</button>';
   skip.hidden=true;play('account-email-idle',{loop:true,endPlate:'email-text-free-v1.png'});announce('Waiting example. Sending a link is not sign-in success; use Open demo sign-in link to simulate verification.');
  }
  function finishPass(blend=true){
   token++;clearTimeout(timer);clearTimeout(fadeTimer);videos.forEach(v=>{v.pause();v.onended=v.onerror=v.ontimeupdate=null;});
   hide();skip.hidden=true;mode=null;stage.classList.remove('account-error-visible');plate.src=options.passPlate;onPass(method);
   videos.forEach(v=>{if(blend&&!motionOff()&&(v.classList.contains('active')||v.classList.contains('fading'))){v.classList.remove('active');v.classList.add('fading');}else v.classList.remove('active','fading');});
   fadeTimer=setTimeout(()=>videos.forEach(v=>v.classList.remove('fading')),600);
  }
  function exit(linked){
   mode='account-exit';stage.dataset.scene=mode;stage.classList.remove('account-error-visible');controls.hidden=true;signed.hidden=!linked;skip.hidden=false;
   if(linked)title('Your holiday.','Linked to you.');else title('Let’s keep','the holiday rolling.');
   announce(linked?'Simulated sign-in succeeded. Travi links the folio and presents the passes.':'Continuing as a guest. Travi presents the same pass choices without linking your account.');
   options.onPassBegin?.();
   play(linked?'account-success-pass':'account-guest-pass',{endPlate:options.passPlate,done:()=>finishPass(),progress:t=>{if(t>=1.9)signed.hidden=true;}});
  }
  function authenticate(provider){
   const result=options.outcome?.()||'success';
   if(result!=='success'){
    const existing=controls.querySelector('.account-error');if(existing)existing.remove();
    const error=document.createElement('p');error.className='account-error';error.setAttribute('role','status');error.textContent=result==='cancelled'?'Sign-in cancelled. Your holiday stays here.':'Couldn’t sign in. Try again or continue as a guest. Your holiday stays here.';controls.prepend(error);
    stage.classList.add('account-error-visible');announce('Simulated '+result+'. Your same holiday is kept; no linking celebration runs.');return;
   }
   method=provider;options.onIdentity?.(provider);exit(true);
  }
  controls.addEventListener('click',event=>{const b=event.target.closest('[data-account]');if(!b)return;switch(b.dataset.account){case 'apple':case 'google':authenticate(b.dataset.account);break;case 'email':email();break;case 'return':stop();providers();plate.src=asset('account-text-free-v1.png');play('account-idle',{loop:true});break;case 'guest':method='guest';options.onIdentity?.('guest');exit(false);break;case 'demo-link':authenticate('email');break;}});
  skip.addEventListener('click',()=>{if(mode==='account-exit')finishPass(false);else if(mode==='account'){stop();plate.src=asset('account-text-free-v1.png');providers();play('account-idle',{loop:true});}else if(mode==='account-email'){stop();plate.src=asset('email-text-free-v1.png');play('account-email-idle',{loop:true,endPlate:'email-text-free-v1.png'});}});
  document.addEventListener('click',event=>{
   const b=event.target.closest('[data-action]');if(!b)return;
   if(b.dataset.action==='passes'){event.preventDefault();event.stopImmediatePropagation();enter();}
   else if(mode&&b.dataset.action==='replay'){event.preventDefault();event.stopImmediatePropagation();if(mode.startsWith('account-email'))email();else enter();}
   else if(mode&&['back','reset'].includes(b.dataset.action)){stop();hide();mode=null;}
   else if(mode&&b.dataset.action==='free'){finishPass(false);}
  },true);
  function stillChange(){if(!mode)return;if(motionOff()){const before=mode;stop();plate.src=before.startsWith('account-email')?asset('email-text-free-v1.png'):asset('account-text-free-v1.png');if(before==='account-exit')finishPass(false);}else if(mode.startsWith('account-email'))play('account-email-idle',{loop:true,endPlate:'email-text-free-v1.png'});else if(mode==='account')play('account-idle',{loop:true});}
  still.addEventListener('change',stillChange);reduced.addEventListener('change',stillChange);
  document.addEventListener('visibilitychange',()=>{if(document.hidden)videos.forEach(v=>v.pause());else if(current&&!motionOff())current.play().catch(()=>{});});
  return {enter,stop,resume(view){enter({fromProof:false});if(view==='account-email')email(false);else if(view==='account-email-sent')sent();},mode:()=>mode};
 }};
})();
