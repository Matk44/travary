"""Adapt the existing proof/desk review with the approved account motion."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / 'onboarding-booking-handoff-v1'
html = (SOURCE / 'motion-review-v1.html').read_text()
for name in ['folio-text-free-v1.png', 'proof-text-free-v1.png', 'pass-text-free-v1.png',
             'save-reaction-v1.mp4', 'card-reaction-v1.mp4', 'pass-presentation-smooth-v2.mp4']:
    html = html.replace(name, '../onboarding-booking-handoff-v1/' + name)
# Original player constructs the card filename; resolve those historical clips.
html = html.replace("shot+'-v1.mp4'", "'../onboarding-booking-handoff-v1/'+shot+'-v1.mp4'")
html = html.replace('<title>Travary — one bit handled</title>', '<title>Travary — Travi account animation review</title>')
html = html.replace('</head>', '<link rel="stylesheet" href="account-motion.css"></head>')
html = html.replace('<script>\n(() =>', '<script src="account-motion.js"></script><script>\n(() =>')
html = html.replace('<p class="eyebrow">Approved art → acting study</p><h1>One bit handled.<br>Then your choice.</h1>',
                    '<p class="eyebrow">Approved account scene → motion review</p><h1>Your holiday.<br>Coming with you.</h1>')
html = html.replace('<p>“Let’s sort the rest” lets Travi file the booking and present the passes. Their live text appears once the paper settles. Continue with free there to carry the same booking into the example holiday.</p>',
                    '<p>“Let’s sort the rest” lets Travi file the booking and offer sign-in. Try Apple, Google, the email-link example or guest continuation, then watch him present the passes.</p>')
html = html.replace('<small>Local motion review. Saving here changes example data only. The Flutter app’s real save, RevenueCat catalog and free flow are separate.</small>',
                    '<div class="account-tools"><label>Test sign-in result<select id="account-result"><option value="success">Success — simulated</option><option value="cancelled">Cancelled</option><option value="failure">Failure</option></select></label><button class="tool" id="replay-account">Replay account entrance</button></div><p class="account-legend">Animation preview only: no account is created, no email is sent and nothing is charged. Sign-in placement and email authentication are not yet wired in Flutter.</p>')
anchor="selectOffer('holiday');show('review');"
assert html.count(anchor) == 1
setup="""const account=TravaryAccountMotion.create({stage,plate,status,still,reduced,
 proofPlate:'../onboarding-booking-handoff-v1/proof-text-free-v1.png',
 passPlate:'../onboarding-booking-handoff-v1/pass-text-free-v1.png',
 onEnter:()=>{show('account');activeShot=null;q('.back').hidden=false;},
 onPassBegin:()=>{q('.footer').hidden=false;},
 onPass:()=>{show('passes');activeShot=null;settleDesk('Your example pass choices are ready.',false);},
 outcome:()=>q('#account-result').value,
});
q('#replay-account').addEventListener('click',()=>account.enter());
selectOffer('holiday');show('proof');play('card-reaction');"""
html = html.replace(anchor, setup)
(ROOT / 'index.html').write_text(html)
print('Built account animation review without changing original studies.')
