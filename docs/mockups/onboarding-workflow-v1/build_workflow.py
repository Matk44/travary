"""Connect existing approved browser studies; never generate artwork or films."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parent
MOCKUPS = ROOT.parent


def replace_once(text, old, new):
    assert text.count(old) == 1, old[:100]
    return text.replace(old, new)


journey = MOCKUPS / 'onboarding-journey-v1'
html = (journey / 'index.html').read_text()
html = html.replace('href="style.css"', 'href="journey.css"')
for filename in ['idle-start-v1.png', 'travi-entrance-playback-v1.mp4',
                 'travi-idle-loop-v1.mp4', 'bali-stage-v1.png', 'travi-cutout-v2.png']:
    html = html.replace('src="' + filename + '"', 'src="../onboarding-journey-v1/' + filename + '"')
html = html.replace('<button type="button" class="choice" data-place="Kyoto">Kyoto</button>', '')
html = html.replace('placeholder="A city, island or country" autocomplete="off" maxlength="80"',
                    'value="Bali" readonly aria-describedby="bali-review-note"')
html = html.replace('<div class="choices">', '<p id="bali-review-note">Bali is the illustrated destination in this motion review.</p><div class="choices">')
html = html.replace('<button class="shortcut" data-handoff="joining a holiday">Joining a holiday?</button>', '')
html = html.replace('<script src="journey.js"></script>', '<script src="embed.js"></script><script src="journey.js"></script>')
(ROOT / 'journey.html').write_text(html)
css = (journey / 'style.css').read_text()
css += '\n/* Embedded review uses the same artwork and controls at the shared phone width. */\nbody{margin:0;background:#fff1da}main{display:block;padding:0;min-height:0}aside{display:none}.screen{width:100%;max-width:none;border-radius:0;box-shadow:none}[hidden]{display:none!important}\n'
(ROOT / 'journey.css').write_text(css)
js = (journey / 'journey.js').read_text()
js = js.replace("key='travary-onboarding-journey-v1'", "key='travary-workflow-intro-v1'")
js = js.replace('motionOff=reduce.matches,', 'motionOff=reduce.matches||workflow.state().stills===true,')
for filename in ['bali-stage-v1.png', 'kyoto-stage-v1.png', 'empty-stage-v1.png',
                 'travi-cutout-v2.png', 'idle-start-v1.png', 'entrance-start-v1.png']:
    js = js.replace("'" + filename + "'", "'../onboarding-journey-v1/" + filename + "'")
js = replace_once(js, 'function persist(){try{sessionStorage.setItem(key,JSON.stringify({phase,draft}))}catch{}}',
                  'function persist(){try{sessionStorage.setItem(key,JSON.stringify({phase,draft}))}catch{}workflow.draft({...draft});}')
js = replace_once(js, 'screen.dataset.destination=draft.destination}',
                  "screen.dataset.destination=draft.destination;workflow.step(phase==='intro'?'destination':'dates',text)}")
js = js.replace('placeInput.value=draft.destination;', "placeInput.value=draft.destination||'Bali';")
start = js.index(" el('next-booking').addEventListener")
end = js.index(" el('restart').addEventListener", start)
js = js[:start] + """ el('next-booking').addEventListener('click',()=>{stopFilms();workflow.emit('open-booking',{...draft,route:'invite'})});
 document.querySelector('[data-handoff="booking import"]').addEventListener('click',()=>{stopFilms();workflow.emit('open-booking',{destination:'Bali',departure:'',returnDate:'',flexible:true,route:'import'})});
 window.addEventListener('workflow-stills',event=>setStill(event.detail));
""" + js[end:]
(ROOT / 'journey.js').write_text(js)

folio = (MOCKUPS / 'onboarding-folio-motion-v2/motion-fragment.template.html').read_text()
assets = {'STAGE': 'bali-stage-prop-free-v1.webp', 'CLOSED': 'closed-folio-v1.webp',
          'OPEN': 'open-folio-delivery.webp', 'GREETING': 'travi-greeting-delivery.webp',
          'RECEIVING': 'travi-receiving-delivery.webp'}
for key, filename in assets.items():
    folio = folio.replace('__' + key + '__', '../onboarding-folio-motion-v1/' + filename)
folio = replace_once(folio, "const root=document.getElementById('travary-folio-fullscreen');",
                     "const root=document.getElementById('travary-folio-fullscreen');\n  const context=workflow.state(),firstDay=context.departure||context.exampleDate||'2026-11-08';\n  const range=context.departure&&context.returnDate?new Intl.DateTimeFormat('en-GB',{day:'numeric',month:'short'}):null;")
folio = folio.replace("kind='Stay',still=false,", "kind='Stay',still=context.stills===true,")
script_start = folio.index('<script>')
markup, script = folio[:script_start], folio[script_start:]
script = script.replace("'2026-12-12'", 'firstDay')
script = script.replace("'2026-12-13'", 'firstDay')
script = replace_once(script,
                      "if(day<firstDay||day>'2026-12-19'){error.textContent='Outside this holiday. Choose 12–19 Dec to preview.';error.hidden=false;return;}",
                      "if(context.departure&&context.returnDate&&(day<context.departure||day>context.returnDate)){error.textContent='Choose a date within your holiday, or go back to change the holiday dates.';error.hidden=false;return;}")
script = script.replace("q('[data-motion-status]').textContent='This study previews TV123 on 12 Dec only · other flights need the actual service';",
                        "q('[data-motion-status]').textContent='This study previews TV123 on '+firstDay+' only · other flights need the actual service';")
script = replace_once(script, "render('saved');saveState();",
                      "cancel();workflow.emit('booking',{title,place,time,start:day,end:day,kind,source:origin});")
script = replace_once(script, "else if(action==='later'){render('later');saveState();}",
                      "else if(action==='later'){cancel();workflow.emit('later');}")
script = replace_once(script, "q('[data-motion-status]').textContent=status[scene];",
                      "q('[data-motion-status]').textContent=status[scene];workflow.step('booking',status[scene]);")
script = replace_once(script, "render('dates',false);restore(window.openai?.widgetState);", """q('.tf-keepsake strong').textContent='Bali';
  q('.tf-keepsake').setAttribute('aria-label','Bali holiday');
  q('.tf-date-range').textContent=range?range.format(new Date(context.departure+'T12:00:00'))+' – '+range.format(new Date(context.returnDate+'T12:00:00')):'Dates not decided';
  q('.tf-stamp').textContent=range?'Dates set':'Dates to come';
  q('.tf-flight-date').value=firstDay;
  if(context.booking){const b=context.booking;fillReview(b.kind,b.title,b.place,b.time,b.start);origin=b.source;render('review',false);}
  else {fillReview('Stay','Palm Garden Stay','Ubud, Bali','15:00',firstDay);render(context.route==='import'?'import':'invite');}
  window.addEventListener('workflow-stills',event=>{still=event.detail;render(scene,false);});""")
folio = markup + script
folio += '<style>body{margin:0;background:#fff1da}#travary-folio-fullscreen .viz-row,#travary-folio-fullscreen .viz-controls{display:none}#travary-folio-fullscreen .tf-preview{padding:0}#travary-folio-fullscreen .tf-phone{width:100%;border-radius:0;box-shadow:none}button{cursor:pointer}button:focus-visible,input:focus-visible{outline:3px solid #bc6632;outline-offset:3px}</style>'
(ROOT / 'folio.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Travary — booking folio</title><script src="embed.js"></script></head><body>' + folio + '</body></html>\n')

handoff = (MOCKUPS / 'onboarding-booking-handoff-v1/motion-review-v1.html').read_text()
for filename in ['folio-text-free-v1.png', 'proof-text-free-v1.png', 'pass-text-free-v1.png']:
    handoff = handoff.replace(filename, '../onboarding-booking-handoff-v1/' + filename)
handoff = handoff.replace('<script>\n(() =>', '<script src="embed.js"></script><script>\n(() =>')
handoff = replace_once(handoff, "const reduced=matchMedia('(prefers-reduced-motion: reduce)');",
                       "const reduced=matchMedia('(prefers-reduced-motion: reduce)');\n const context=workflow.state();still.checked=context.stills===true;")
handoff = replace_once(handoff, "let scene='review',booking={title:'Lagoon Retreat',start:'2026-11-08',end:'2026-11-09'},",
                       "let scene='review',booking=context.booking||{title:'',start:context.departure||context.exampleDate,end:context.departure||context.exampleDate},")
handoff = replace_once(handoff, "date(booking.start)+' → '+date(booking.end)",
                       "date(booking.start)+(booking.start===booking.end?'':' → '+date(booking.end))")
handoff = replace_once(handoff, "q('.pass-buy').textContent='Get '+catalog[role].title;}",
                       "q('.pass-buy').textContent='Get '+catalog[role].title;workflow.draft({selectedOffer:role});}")
handoff = replace_once(handoff, "if(offer){selectOffer(offer.dataset.offer);return;}",
                       "if(offer){if(!offer.disabled)selectOffer(offer.dataset.offer);return;}")
handoff = replace_once(handoff, "const guard=generation;film.src=shot==='pass-presentation'?'pass-presentation-smooth-v2.mp4':shot+'-v1.mp4';",
                       "const guard=generation;film.src='../onboarding-booking-handoff-v1/'+(shot==='pass-presentation'?'pass-presentation-smooth-v2.mp4':shot+'-v1.mp4');")
handoff = replace_once(handoff, "[next];copy();",
                       "[next];copy();workflow.step({review:'booking',proof:'proof',passes:'passes',free:'holiday'}[next],status.textContent);")
handoff = replace_once(handoff, "case 'free':if(scene==='passes'){show('free');activeShot=null;}break;",
                       "case 'free':if(scene==='passes'){show('free');activeShot=null;workflow.emit('complete',{choice:'free'});}break;")
handoff = replace_once(handoff, "case 'back':show('proof');activeShot='card-reaction';break;",
                       "case 'back':if(!context.booking){workflow.emit('back-booking');break;}show('proof');activeShot='card-reaction';break;")
handoff = replace_once(handoff, "case 'buy':case 'restore':q('dialog').showModal();break;", """case 'buy':{
       const result=workflow.state().purchaseResult;
       if(result==='success'){show('free');activeShot=null;workflow.emit('complete',{choice:selected});}
       else {q('dialog p').textContent=result==='cancelled'?'Test purchase cancelled. Your holiday is kept; choose a pass again or continue with free.':'Test purchase failed. Your holiday is kept; try again or continue with free.';q('dialog').showModal();}
       break;
     }
     case 'restore':q('dialog p').textContent='Preview restore only. No existing purchases are connected to this local walkthrough.';q('dialog').showModal();break;""")
handoff = replace_once(handoff, "selectOffer('holiday');show('review');", """q('.proof-card .kind').textContent=(booking.kind||'Booking').toUpperCase();
 const holidayLabel='Bali holiday · '+(context.departure&&context.returnDate?date(context.departure)+' – '+date(context.returnDate):'Dates not decided');
 q('.tag').textContent=holidayLabel;q('.plan>p').textContent=holidayLabel;
 q('.plan article').hidden=!context.booking;
 if(!context.booking){q('.plan>p:last-of-type').textContent='Add your bookings when you are ready.';q('.back').setAttribute('aria-label','Back to booking choices');q('.plan button').textContent='Back to booking choices';}
 const details=document.createElement('p');details.textContent=context.booking?[booking.time,booking.place].filter(Boolean).join(' · '):'';q('.plan article').append(details);
 const eligible=Boolean(context.departure&&context.returnDate)&&(new Date(context.returnDate)-new Date(context.departure))/86400000<30;
 if(!eligible){const offer=q('[data-offer="holiday"]');offer.disabled=true;offer.setAttribute('aria-disabled','true');catalog.holiday.scope=context.departure&&context.returnDate?'Up to 30 days':'Dates needed';}
 selectOffer(eligible&&context.selectedOffer!=='annual'?'holiday':'annual');
 window.addEventListener('workflow-stills',event=>{if(still.checked!==event.detail){still.checked=event.detail;still.dispatchEvent(new Event('change'));}});
 if(context.choice){show('free');activeShot=null;}
 else if(context.step==='passes'){show('passes');activeShot=context.booking?'pass-presentation':null;settleDesk('Your pass choices are ready.',false);}
 else if(context.booking){show('proof');status.textContent='Example booking added. Travi straightens your checked details.';play('card-reaction');}
 else {show('passes');activeShot=null;settleDesk('Choose a pass or continue with free. Your booking can come later.',false);q('.plan>p:last-of-type').textContent='Add your bookings when you are ready.';}""")
handoff = handoff.replace('</style>', '\nbody{margin:0;background:#fff1da}main{display:block;padding:0;min-height:0}.notes{display:none}.phone{width:100%;max-width:none;border-radius:0;box-shadow:none}.offer:disabled{cursor:default;opacity:.65}.footer small{font-size:11px}\n</style>')
handoff = handoff.replace('</head>', '<link rel="stylesheet" href="../onboarding-account-motion-v1/account-motion.css"></head>')
handoff = handoff.replace('<script src="embed.js"></script>', '<script src="embed.js"></script><script src="../onboarding-account-motion-v1/account-motion.js"></script>')
account_setup = """const account=TravaryAccountMotion.create({stage,plate,status,still,reduced,
 proofPlate:'../onboarding-booking-handoff-v1/proof-text-free-v1.png',
 passPlate:'../onboarding-booking-handoff-v1/pass-text-free-v1.png',
 onEnter:()=>{show('account');activeShot=null;q('.back').hidden=false;},
 onPassBegin:()=>{q('.footer').hidden=false;},
 onPass:method=>{workflow.draft({accountMethod:method||workflow.state().accountMethod,accountCompleted:true,accountView:null});show('passes');activeShot=null;settleDesk('Your example pass choices are ready.',false);},
 onStatus:(mode,message)=>{workflow.draft({accountView:mode});workflow.step('account',message);},
 onIdentity:method=>workflow.draft({accountMethod:method}),
 outcome:()=>workflow.state().authResult||'success',
});
"""
handoff = replace_once(handoff, "q('.proof-card .kind').textContent", account_setup + "q('.proof-card .kind').textContent")
handoff = replace_once(handoff, "if(context.choice){show('free');activeShot=null;}", """if(context.choice){show('free');activeShot=null;}
 else if(context.step==='account'){if(context.accountMethod&&context.accountView==='account-exit'){show('passes');activeShot=null;settleDesk('Your pass choices are ready.',false);}else account.resume(context.accountView);}""")
handoff = replace_once(handoff, "else {show('passes');activeShot=null;settleDesk('Choose a pass or continue with free. Your booking can come later.',false);q('.plan>p:last-of-type').textContent='Add your bookings when you are ready.';}",
 "else {account.enter({fromProof:false});q('.plan>p:last-of-type').textContent='Add your bookings when you are ready.';}")
(ROOT / 'handoff.html').write_text(handoff)

(ROOT / 'sources.json').write_text(json.dumps({
    'date': '2026-10-09', 'purpose': 'Connected local onboarding review, now with approved pre-paywall account motion',
    'sources': ['onboarding-journey-v1', 'onboarding-folio-motion-v2', 'onboarding-booking-handoff-v1', 'onboarding-account-motion-v1'],
    'media': 'Approved originals and reviewed derivatives; new account films recorded in onboarding-account-motion-v1/jobs.json and processing.json',
    'newArtOrVideo': True,
    'boundary': 'Browser example state only; simulated sign-in/email/purchases, not native services, RevenueCat or production billing',
}, indent=2) + '\n')
print('Built connected journey, folio and handoff pages from the existing studies.')
