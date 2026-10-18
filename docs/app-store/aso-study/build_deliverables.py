#!/usr/bin/env python3
"""Rebuild local proposal only. No network, console or repository source edits."""
from pathlib import Path
from PIL import Image
import json, re, hashlib, subprocess
ROOT=Path('/Users/khairofamily/AndroidStudioProjects/Travary')
OUT=ROOT/'docs/app-store/aso-study'
TITLE='Itinerary App - Travary'
DATE='2026-10-18'
S={
'apple_metadata':'https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information',
'apple_page':'https://developer.apple.com/app-store/product-page/',
'apple_search':'https://developer.apple.com/app-store/search/',
'apple_cpp':'https://developer.apple.com/help/app-store-connect/create-custom-product-pages/configure-multiple-product-page-versions',
'apple_assets':'https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets',
'apple_specs':'https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications',
'apple_screens':'https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications',
'apple_best':'https://developer.apple.com/app-store/asset-best-practices/',
'apple_2026':'https://developer.apple.com/videos/play/wwdc2026/205/',
'apple_tags':'https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-tags',
'apple_locales':'https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations',
'apple_ppo':'https://developer.apple.com/help/app-store-connect/create-product-page-optimization-tests/overview-of-product-page-optimization/',
'apple_iap':'https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/',
'google_listing':'https://support.google.com/googleplay/android-developer/answer/9859152',
'google_custom':'https://support.google.com/googleplay/android-developer/answer/9867158',
'google_graphics':'https://support.google.com/googleplay/android-developer/answer/9866151',
'google_locales':'https://support.google.com/googleplay/android-developer/answer/9844778',
'google_tags':'https://support.google.com/googleplay/android-developer/answer/9859673',
'google_experiments':'https://support.google.com/googleplay/android-developer/answer/12053285',
'google_testing':'https://support.google.com/googleplay/android-developer/answer/14151465',
'product':str(ROOT/'CLAUDE.md'),'pricing':str(ROOT/'lib/domain/pricing.dart'),
'access':str(ROOT/'lib/logic/access.dart'),'import':str(ROOT/'functions/src/smartImport.ts'),
'widgets':str(ROOT/'docs/COUNTDOWN_WIDGET.md'),'launch':str(ROOT/'docs/LAUNCH_CHECKLIST.md'),
'creative_manifest':str(ROOT/'docs/mockups/app-store-creative-v1/exports/delivery-manifest.json'),
'observed':str(OUT/'evidence/CONSOLE_OBSERVATIONS.md')}
fields=[]; assets=[]
def slug(t): return re.sub('[^a-z0-9]+','-',t.lower()).strip('-')
def add(store,loc,page,label,value=None,limit=None,unit='characters',action='fill',section=None,verified=False,deps=None,refs=None,asset=None,bucket=None,order=None,status='proposed/unapproved',is_copy=None):
    rid=f'{store}-{loc or "all"}-{page}-{slug(label)}'
    if order is not None: rid+=f'-{slug(bucket or "asset")}-{order:02}'
    if any(x['id']==rid for x in fields): raise ValueError(rid)
    f=dict(id=rid,store=store,app_id='6818495253' if store=='apple' else 'com.travary.app',locale=loc,page_type='default' if page=='default' else ('custom_product_page' if page=='family' and store=='apple' else 'custom_store_listing' if page=='family' else page),page_reference_name=('Family & packing' if store=='apple' else 'Family trip planner') if page=='family' else None,console_section=section or ('App Store > iOS App Version 1.0' if store=='apple' else 'Grow users > Store presence > Store listings > Default store listing'),field_label=label,action=action,value=value,source_file=None,character_count=len(value) if isinstance(value,str) else None,utf8_byte_count=len(value.encode('utf-8')) if isinstance(value,str) else None,limit=limit,limit_unit=unit if limit is not None else None,asset_path=str(asset) if asset else None,device_bucket=bucket,upload_order=order,dependencies=['Owner approval of this proposal']+(deps or []),status=status,source_references=[S.get(x,x) for x in refs or (['apple_metadata'] if store=='apple' else ['google_listing'])],navigation_verified=verified)
    f['copy_field']=is_copy if is_copy is not None else isinstance(value,str)
    if isinstance(value,str):
        p=OUT/'copy'/store/(loc or 'shared')/page/(slug(label)+(f'-{slug(bucket)}-{order:02}' if order is not None else '')+'.txt')
        p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(value.encode('utf-8')); f['source_file']=str(p)
    if limit is not None and isinstance(value,str):
        measured=f['utf8_byte_count'] if unit=='UTF-8 bytes' else f['character_count'];f['remaining_capacity']=limit-measured;f['validation']='PASS' if measured<=limit else 'FAIL'
    else:f['remaining_capacity']=None;f['validation']='N/A' if not isinstance(value,str) else 'COUNTED; no verified text cap'
    fields.append(f);return f

def description(store,loc,family=False):
    us=loc=='en-US'; holiday='vacation' if us else 'holiday'; organize='Organize' if us else 'Organise'; traveler='travelers' if us else 'travellers'; organizer='organizer' if us else 'organiser'
    first=(f'Bring your family trip together. Travary keeps bookings, daily plans and saved tickets in one place, with shared trips and packing lists for up to 6 people, including the {organizer}, with a pass.' if family else f'Your bookings, in order. Your tickets, close at hand. Travary is an itinerary app for the trips you have booked, from the first confirmation to the journey home.')
    parts=[first,
    f'ADD A BOOKING. SEE YOUR TRIP TAKE SHAPE.\nAdd flights, stays, activities and restaurant bookings. Travary builds trips around their dates, so you can start with what you have already booked. {organize} a weekend away or a family {holiday} without building a plan from scratch.',
    'KNOW WHAT IS NEXT\nToday puts the day\'s bookings in time order. Keep confirmation details and tickets beside the plans they belong to, and spot gaps such as a night without a stay or a missing flight home.',
    'KEEP SAVED TICKETS OFFLINE\nSave your bookings and ticket files before you leave. Open them without a connection when you need them. Saved bookings and tickets stay accessible on every plan, including after a pass ends. Importing and syncing shared changes need an internet connection.',
    'CHECK THE DRAFT, THEN KEEP IT\nGive Smart Import a booking screenshot, photo or PDF. Travi reads it into a draft for you to check and correct before saving. You get 2 free Smart Imports in total. Your imported source file counts towards your ticket-file allowance.',
    f'TRAVEL TOGETHER\nWith a pass, share a trip with up to 6 people, including the {organizer}. Keep the group\'s bookings and packing list together, with each person\'s tickets easy to find. One pass covers the people sharing that trip.',
    f'ENJOY THE COUNTDOWN\nGive each trip a destination postcard, tick off packing and to-do lists, and set reminders. Keep your next {holiday} in sight with a home-screen countdown widget.'+(' Widgets require iOS 17 or later.' if store=='apple' else ''),
    'KEEP PERSONAL DOCUMENTS PERSONAL\nPersonal travel documents stay on your device behind its lock. They are not automatically shared with your trip or sent to Smart Import.',
    f'START FREE. CHOOSE A PASS WHEN YOU NEED MORE.\nCreate trips and add bookings free. Each free trip can keep 2 ticket files. A pass adds sharing, shared packing, more ticket files and more Smart Imports, subject to a daily usage limit.\n\nHoliday Pass is a one-time purchase for one trip of up to 30 days, with pass features available until 7 days after it ends. Annual Pass is a yearly subscription that renews automatically unless cancelled. Prices are shown in the app before purchase.'+(' Manage or cancel Annual Pass in your App Store account settings.' if store=='apple' else ' Manage or cancel Annual Pass in Google Play.'),
    'Start with your next booking. Travi will meet you there.',
    'Support: https://travary.app/support\nPrivacy: https://travary.app/privacy\nTerms: https://travary.app/terms']
    return '\n\n'.join(parts)

for loc in ['en-US','en-GB','en-AU']:
    kw='family,shared,packing,checklist,vacation,countdown,booking,organizer,documents,reminder' if loc=='en-US' else 'family,shared,packing,checklist,holiday,countdown,booking,organiser,documents,reminder'
    for label,val,lim in [('Name',TITLE,30),('Subtitle','Trip planner & offline tickets',30),('Keywords',kw,100),('Promotional Text','Start with a booking. See each day in order, keep saved tickets offline and spot missing stays. Share trips and packing with up to 6 people with a pass.',170),('Description',description('apple',loc),4000)]:
        add('apple',loc,'default',label,val,lim,'UTF-8 bytes' if label=='Keywords' else 'characters',action='retain' if label=='Name' else 'fill',section='App Information' if label in ['Name','Subtitle'] else 'App Store > iOS App Version 1.0',verified=loc=='en-US',deps=['Release-build feature checks in VALIDATION.md'],refs=['apple_page' if label in ['Name','Subtitle'] else 'apple_metadata','product','pricing','import'])
    for label,url in [('Support URL','https://travary.app/support'),('Marketing URL','https://travary.app/')]:add('apple',loc,'default',label,url,verified=loc=='en-US')
    add('apple',loc,'default',"What's New in This Version",action='not applicable',deps=['First version 1.0: field not applicable; do not paste release notes'],verified=loc=='en-US')
    add('apple',loc,'family','Promotional Text','Keep the family on the same page. Share bookings and packing with up to 6 people, including the organiser, with a pass. Saved tickets stay accessible offline.'.replace('organiser','organizer') if loc=='en-US' else 'Keep the family on the same page. Share bookings and packing with up to 6 people, including the organiser, with a pass. Saved tickets stay accessible offline.',170,section='Custom Product Pages > Family & packing > Localization',deps=['Approved default metadata and CPP eligibility','No independent title/subtitle/description on CPP'],refs=['apple_cpp','pricing'])
    add('apple',loc,'family','Keywords',value=['family','packing','shared'],action='select',section='Custom Product Pages > Family & packing > Keywords',deps=['These tokens must appear in eligible selector from latest approved locale Keywords; capture exact selected entries before approval to Publish','Do not add Itinerary App or subtitle terms as assumed eligible'],refs=['apple_cpp'],status='proposed/unapproved; blocked until eligible selector verified',is_copy=False)
    add('apple',loc,'family','App Deep Link',action='not applicable',section='Custom Product Pages > Family & packing',deps=['Omit. No tested family destination route has been established'],refs=['apple_cpp'])
    for page in ['default','family']:
        short=('Keep bookings in order, save tickets offline and spot gaps in your trip.' if page=='default' else 'Shared trips and packing for up to 6 people with a pass. Saved tickets offline.')
        for label,val,lim in [('App name',TITLE,30),('Short description',short,80),('Full description',description('google',loc,page=='family'),4000)]:
            add('google',loc,page,label,val,lim,action='retain' if label=='App name' else 'fill',section=f'Grow users > Store presence > Store listings > {"Default store listing" if page=="default" else "Family trip planner"} > '+loc,deps=['Create listing later after approval; no default listing currently exists','Android release-build feature checks'],refs=['google_listing','google_custom' if page=='family' else 'google_listing','pricing','import'])
    for product, name, desc in [('holiday_pass','Holiday Pass','Sharing and extras for a trip up to 30 days'),('travary_annual_pass','Annual Pass','Sharing and extras for your trips, yearly')]:
        add('apple',loc,product,'Display Name',name,30,section=f'Monetization > {"Subscriptions > Travary Annual Pass" if product=="travary_annual_pass" else "In-App Purchases > holiday_pass"} > Display Name and Description',verified=product=='travary_annual_pass' and loc=='en-US',deps=['Keep product ID and commercial settings unchanged','Verify subscription counter if different from IAP reference; proposed copy fits conservative 30/45 limits'],refs=['apple_iap','pricing'])
        add('apple',loc,product,'Description',desc,45,section=f'Monetization > {product} > Display Name and Description',verified=product=='travary_annual_pass' and loc=='en-US',deps=['Purchase metadata review separate from listing; no store promotion at launch'],refs=['apple_iap','pricing'])

add('apple',None,'family','Reference Name','Family & packing',100,section='Custom Product Pages > Create Custom Product Page',verified=True,refs=['observed','apple_cpp'])
add('apple',None,'family','Product Page URL',action='owner input required',section='Custom Product Pages > Family & packing',deps=['Generated only after page creation; never guess a ppId'],refs=['apple_cpp'])
add('google',None,'default','Default language','English (United States) – en-US',action='select',section='Store listings > Create default store listing',refs=['google_locales'],deps=['Main default language proposed; creation form unobserved'])
add('google',None,'family','Listing name','Family trip planner',section='Store listings > Create custom store listing',deps=['Internal name; field cap unobserved. Verify before later save'],refs=['google_custom'])
add('google',None,'family','Targeting','Search keywords',action='select',section='Store listings > Create custom store listing > Targeting',refs=['google_custom'])
add('google',None,'family','Search keywords',value=['family trip planner','shared trip planner'],action='select',section='Custom store listing > Targeting > Search keywords > View variations',deps=['Check availability and each spelling/translation variation; exclude navigation/generation/booking-service intent','If no suitable keywords available keep page as local proposal, no country-target workaround'],refs=['google_custom'],status='proposed/unapproved; blocked until keyword bundle verified',is_copy=False)
add('google',None,'family','Default language','English (United States) – en-US',action='select',section='Custom store listing > Store listing details',refs=['google_custom','google_locales'])
for label in ['Countries','User state','Google Ads campaign','Unique URL parameter']:
    add('google',None,'family',label,action='not applicable',section='Custom store listing > Targeting',deps=['Do not combine extra targeting in first keyword-page launch; system URL recorded after creation if supplied'],refs=['google_custom'])

for store in ['apple','google']:
    section='App Information' if store=='apple' else 'Grow users > Store presence > Store settings'
    add(store,None,'default','Primary Category' if store=='apple' else 'Category','Travel' if store=='apple' else 'Travel & Local',action='select',section=section,verified=True,refs=['apple_page' if store=='apple' else 'google_tags','observed'])
    if store=='apple':
        add(store,None,'default','Secondary Category',action='not applicable',section=section,verified=True,deps=['Leave unset; no second category needed'])
        add(store,None,'default','App Tags',action='owner input required',section='App Information > App Tags',deps=['No assigned tags observed. Apple generates/reviews tags; retain accurate offered itinerary/trip tags, reject misleading maps/AI generator tags; no arbitrary tag entry'],refs=['apple_tags'],status='proposed/unapproved; not currently available')
        add(store,None,'default','Copyright',limit=200,action='owner input required',verified=True,deps=['Owner must identify actual rights holder and year; developer display name is not proof of legal ownership'])
        add(store,None,'default','License Agreement','Standard Apple License Agreement',action='retain',section=section,verified=True,refs=['observed'])
        add(store,None,'default','Privacy Policy URL','https://travary.app/privacy',section='App Privacy',refs=['apple_metadata'])
        add(store,None,'default','Terms URL (description link)','https://travary.app/terms',action='retain',section='Description; no separate standard-EULA terms URL field',refs=['product'])
    else:
        add(store,None,'default','App or game','App',action='retain',section=section,verified=True,refs=['observed'])
        add(store,None,'default','Tags',value=['Travel & local'],action='select',section=section+' > Manage tags',verified=True,deps=['Exact tag observed; select only this relevant tag, do not fill five for its own sake'],refs=['google_tags','observed'],is_copy=False)
        add(store,None,'default','Email address','dreamprayer.dev@gmail.com',section=section+' > Store listing contact details',verified=True,refs=['https://travary.app/support','observed'])
        add(store,None,'default','Website','https://travary.app/',section=section+' > Store listing contact details',verified=True,refs=['https://travary.app/','observed'])
        add(store,None,'default','Phone number',action='not applicable',section=section+' > Store listing contact details',verified=True,deps=['Optional; no owner-approved public phone. Leave blank'])
        add(store,None,'default','Privacy policy','https://travary.app/privacy',section='Policy and programs > App content > Privacy policy',refs=['https://travary.app/privacy','google_listing'])
        add(store,None,'default','Account deletion web link','https://travary.app/delete-account',section='App content > Data safety > Data deletion',deps=['Validate end-to-end deletion flow before declaration'],refs=['https://travary.app/delete-account'])
        add(store,None,'default','Advertise my app outside of Google Play',value=True,action='retain',section=section+' > External marketing',verified=True,deps=['Observed checked; preserve, this study authorizes no paid campaign'],refs=['observed'],is_copy=False)

admin={
'apple':[
('Age Ratings','App Information > Age Ratings','Complete questionnaire from release content; not inferred from competitors'),
('Content Rights','App Information > Content Rights','Owner confirms rights to artwork and data'),
('App Privacy declarations','App Privacy','Audit Firebase, RevenueCat, Smart Import backend, storage and retention; repository checklist is not signed declaration'),
('Accessibility declarations','App Accessibility','Device testing evidence required; no untested accessibility claims'),
('Export compliance','Build / App Information','Use actual encryption implementation and legal review as needed'),
('Regulated Medical Device Status','App Information','Owner completes applicable questionnaire; no invented declaration'),
('Digital Goods and Services questionnaire','App Information','Owner completes questionnaire if surfaced'),
('Trader status and contact','App Information / Business','Retain existing verified status; owner resolves required trader/legal details'),
('App Review Contact','iOS App Version 1.0 > App Review Information','Name, phone, email require owner input'),
('Sign-in required','iOS App Version 1.0 > App Review Information','Observed checked with blank credentials. Verify guest review path on selected build; do not simply uncheck'),
('Username and Password','iOS App Version 1.0 > App Review Information','Only provide dedicated review credentials if necessary; do not invent or save secrets in this public handover'),
('Notes','iOS App Version 1.0 > App Review Information','Provide tested review steps and pass purchase access after build validation'),
('Attachment','iOS App Version 1.0 > App Review Information','Only if reviewer needs specific supporting evidence'),
('Pricing and Availability','Pricing and Availability','Confirm free app distribution territories and device availability; do not infer selected app countries from subscription countries'),
('App Store Version Release','iOS App Version 1.0 > App Store Version Release','Observed automatic release. Recommend manual release only in later approved setup to retain launch control'),
('Build','iOS App Version 1.0 > Build','Observed build 4 version 1.0.0; owner identifies release candidate after checks'),
('In-App Purchases and Subscriptions','iOS App Version 1.0','Confirm both first products attached to first app review; Annual is Prepare for Submission'),
('Purchase pricing and availability','Monetization','Annual AU AUD59.99 observed, not full US/UK/Google/Holiday validation. No price/trial copy. Keep prices unchanged'),
('Subscription group display name','Subscriptions > Travary Subscriptions','Group localization not configured. Confirm intended customer name and current limit before filling'),
('Purchase options and Family Sharing','Subscriptions > Travary Annual Pass','Apple Family Sharing off; distinct from in-app six-person sharing. Multiseat allowed by default; owner decides policy, no silent change'),
('Tax, banking and agreements','Business','Owner-only legal/account setup outside copywriting')],
'google':[
('Data safety','App content','Owner signs after SDK/network/storage audit, including account deletion'),
('App access','App content','Test reviewer guest and paid paths; supply credentials only if required'),
('Ads declaration','App content','Verify shipped SDKs; do not infer from no ads in copy'),
('Content rating','App content','Complete IARC questionnaire from actual content'),
('Target audience and content','App content','Family travel does not automatically mean child-directed app; owner declares audience'),
('Financial features','App content','Complete applicable declaration from actual app'),
('Health apps','App content','Complete applicable declaration from actual app'),
('Permissions declarations','App content','Review any sensitive permissions surfaced for actual release manifest'),
('Government apps / news declarations','App content','Complete any applicable mandatory questionnaires'),
('Developer contact and verification','Developer account','Account dashboard says verification tasks pending; owner completes privately'),
('Countries and regions','Test and release > Production','Owner chooses initial distribution; study recommends AU first, then UK and US'),
('Pricing','Monetize with Play','Confirm free base app; paid product IDs, regional prices, no trial assumed'),
('Subscriptions and one-time products','Monetize with Play > Products','Verify holiday_pass, travary_annual_pass and base plan travary-annual-pass in live account; do not create duplicates'),
('Production access','Dashboard','0 closed testers observed; at least12 opted in continuously14 days plus production application required'),
('App bundle and signing','Test and release','Confirm signed release, target API, device support, widget/flight tests'),
('Release notes','Test and release > Track > Release details','Separate release-specific text, not listing description; derive from exact build'),
('Managed publishing','Publishing overview','Record actual current state and owner-approved publishing mode; do not assume Save prevents automatic rollout')]
}
for store,items in admin.items():
    for label,section,dep in items:
        add(store,None,'administration',label,action='owner input required',section=section,deps=[dep],refs=['launch','observed'],status='proposed/unapproved; blocked on owner/product evidence')

subjects={1:('today','Your holiday,\nsorted into days.','Flights, stays, tickets and tables, in order.','Today shows the day\'s bookings in time order.'),2:('countdown','Counting down\nto the next one.','A postcard from where you\'re going.','A destination postcard and countdown to the next trip.'),3:('trip','It spots\nwhat\'s missing.','The night without a stay. The flight home.','The trip plan highlights a missing stay and flight home.'),4:('smart-import','Hand Travi\nthe confirmation.','Smart Import reads screenshots and PDFs.','Smart Import reads a confirmation into a draft to check. Two free imports, then a pass.'),5:('flight','Just the\nflight number.','The board flips in the times and airports.','Flight number entry helps fill in flight details.'),6:('family','Everyone on\nthe same page.','Up to 6 people, each with their own tickets.','A shared trip for up to six people, including the organiser, with a pass.'),7:('tickets','Tickets that work\nwith no signal.','Saved bookings and tickets, on every plan.','Saved bookings and tickets remain accessible offline on every plan.'),8:('passport','Your passport stays\non your phone.','Behind Face ID. Checked against your next trip.','Personal travel documents stay on the device behind its lock.'),9:('packing','Packed\ntogether.','One packing list. Share it with a pass.','A trip packing checklist, with shared packing available with a pass.'),10:('trips','Every trip gets\nits own postcard.','Drawn for where you\'re going.','Trips displayed with illustrated destination postcards.'),11:('widget','Your next trip,\non your home screen.','A countdown widget, with Travi in it.','A home-screen countdown widget for the next trip.')}
orders={'apple':{'default':[1,7,3,6,4,9,2,11,8,10],'family':[6,9,1,7,3,4,2,11,8,10]},'google':{'default':[1,7,3,6,4,9,2,11],'family':[6,9,1,7,3,4,2,11]}}

def media_info(p):
    if p is None:return dict(width=None,height=None,format=None,duration_seconds=None,fps=None,audio_streams=None,sha256=None)
    if p.suffix=='.png':
        im=Image.open(p); info=dict(width=im.width,height=im.height,format='PNG',mode=im.mode,has_alpha='A' in im.getbands(),duration_seconds=None,fps=None,audio_streams=None)
    else:
        j=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(p)]));v=next(s for s in j['streams'] if s['codec_type']=='video');n,d=map(int,v['r_frame_rate'].split('/'));info=dict(width=v['width'],height=v['height'],format='MP4',duration_seconds=float(j['format']['duration']),fps=n/d,audio_streams=sum(s['codec_type']=='audio' for s in j['streams']))
    info['sha256']=hashlib.sha256(p.read_bytes()).hexdigest();return info

def asset_record(store,loc,page,placement,p,bucket,order=None,subject=None,required=True,status='existing; proposed assignment; owner review required',requirements=None,active=True):
    aid=f'{store}-{loc}-{page}-{slug(placement)}-{slug(bucket)}'+(f'-{order:02}' if order else f'-subject-{subject:02}' if subject else '')
    item=dict(id=aid,store=store,locale=loc,page=page,placement=placement,asset_path=str(p) if p else None,device_bucket=bucket,upload_order=order,subject=subject,required=required,status=status if p else 'MISSING: capture/adaptation and owner approval required',active_assignment=active,requirements=requirements or [],**media_info(p))
    if subject:
        _,headline,caption,alt=subjects[subject];item.update(headline=headline,caption=caption,headline_character_count=len(headline),caption_character_count=len(caption),purchase_disclosure='2 free, then a pass' if subject==4 else 'With a pass' if subject==6 else 'Share it with a pass.' if subject==9 else None)
    assets.append(item)
    if active:
        add(store,loc,page,placement,action='upload' if p else 'owner input required',section=('iOS App Version 1.0' if page=='default' else 'Custom Product Pages > Family & packing')+' > '+placement if store=='apple' else ('Store listings > '+('Default store listing' if page=='default' else 'Family trip planner')+' > Graphics'),verified=False,deps=['Preview exact locale, crop, safe areas, order, purchase labels and device UI before later approval']+(requirements or []),refs=['apple_screens' if placement=='Screenshots' else 'apple_specs'] if store=='apple' else ['google_graphics'],asset=p,bucket=bucket,order=order,status='proposed/unapproved' if p else 'proposed/unapproved; missing asset',is_copy=False)
    return item

for store in ['apple','google']:
 for loc in ['en-US','en-GB','en-AU']:
  for page in ['default','family']:
   for index,sub in enumerate(orders[store][page],1):
    if store=='apple':
     for bucket,suffix in [('iPhone with Dynamic Island (medium display)','_1206x2622'),('iPhone with Dynamic Island (large display)','')]:
      p=ROOT/f'docs/mockups/app-store-screenshots-v1/final/{sub:02}-{subjects[sub][0]}{suffix}.png'
      asset_record(store,loc,page,'Screenshots',p,bucket,index,sub,requirements=['Same existing English artwork reused across all three locales; US artwork still says holiday','Device bucket label recheck in current Media Manager'])
     asset_record(store,loc,page,'Screenshots',None,'iPad 13-inch',index,sub,requirements=['Capture actual iPad release UI at 2064x2752 or 2048x2732; no stretched iPhone','Universal target currently includes iPad; cannot omit without separately approved engineering change'])
    else:
     asset_record(store,loc,page,'Phone screenshots',None,'Android phone 1080x1920',index,sub,requirements=['Capture actual Android release UI; create approved 9:16 composition, opaque PNG or JPEG','Keep first three focused on actual UI; captions at most20% of frame','Android wording: device lock, not Face ID; existing iPhone artwork only a creative reference'])
     add(store,loc,page,'Screenshot alt text',subjects[sub][3].replace('organiser','organizer') if loc=='en-US' else subjects[sub][3],140,section=f'Store listings > {page} > Phone screenshots > Alt text',deps=['Bind to final matching Android screenshot after capture'],refs=['google_graphics'],bucket='Android phone 1080x1920',order=index)
   if store=='apple':
    for placement,stem in [('Header','travary-header-v4'),('Search Results','travary-search-v5')]:
     base=ROOT/'docs/mockups/app-store-creative-v1/exports'
     asset_record(store,loc,page,placement,base/(stem+'.png'),'iPhone and iPad; iOS/iPadOS27+',requirements=['Approved underlying still; assignment/crop still needs owner review','Shared English art: no locale-specific renders exist'])
     asset_record(store,loc,page,placement+' optional loop',base/(stem+'-loop-v2.mp4'),'iPhone and iPad; iOS/iPadOS27+',required=False,status='HOLD: existing loop revision2; final playback approval absent',requirements=['Do not upload alongside still to a single slot','Owner playback approval then native placement preview'],active=False)
    add(store,loc,page,'App Previews',action='not applicable',section=f'{page} > App Previews and Screenshots',deps=['Launch without preview; 7-second brand loops belong in Header/Search Results, not app-preview slot'],refs=['apple_page'])
   else:
    asset_record(store,loc,page,'App icon',ROOT/'assets/branding/google_play_icon.png','All supported Android devices',requirements=['Existing512x512RGB icon; confirm actual adaptive launcher icon matches'])
    asset_record(store,loc,page,'Feature graphic',None,'1024x500',requirements=['Opaque24-bitPNG orJPEG; adapt existing approved mascot with actual Android itinerary UI','Headline: Your bookings, in order. for default; Travel together. for family','Do not resize Apple header/search artwork; approve static composition first'])
    add(store,loc,page,'Feature graphic alt text','Travi beside a day of travel bookings.' if page=='default' else 'Travi beside a shared trip and packing checklist.',140,section=f'Store listings > {page} > Feature graphic > Alt text',refs=['google_graphics'],deps=['Verify matches final missing graphic'])
    add(store,loc,page,'Video',action='not applicable',section=f'Store listings > {page} > Graphics > Video',deps=['No launch video; this field takes YouTube URL, not Apple MP4'],refs=['google_graphics'])
    for bucket in ['7-inch tablet','10-inch tablet']:
     for index,sub in enumerate(orders[store][page][:4],1):asset_record(store,loc,page,'Tablet screenshots',None,bucket,index,sub,required=False,requirements=['Large-screen coverage must reflect supported release UI; capture4 actual frames at1080–7680 pixels,16:9 or9:16 if seeking tablet promotion','Do not claim optimized tablet support without layout testing'])
asset_record('apple','all','default','App icon',ROOT/'assets/branding/travary_app_icon_master.png','Build asset catalog 1024x1024',required=True,requirements=['Delivered through validated app build; not standalone listing upload'],active=False)
add('apple',None,'default','App icon',action='retain',section='Selected build > App icon',asset=ROOT/'assets/branding/travary_app_icon_master.png',deps=['Verify build icon matches master; replacement requires engineering/build'],refs=['product'])
for store in ['apple','google']:
 add(store,None,'administration','Promoted purchases / offers',action='not applicable',deps=['No promotion at launch; Holiday Pass requires trip context; purchase-from-store handling and approved promotional1024x1024 image not verified'],refs=['apple_iap'] if store=='apple' else ['google_listing'])

for label,text in [('Default first headline','Your bookings, in order.'),('Offline headline','Saved tickets. No signal needed.'),('Gaps headline','Spot the missing stay.'),('Family headline','One trip. Up to six people.'),('Import headline','Check the draft. Keep the booking.'),('Family feature graphic headline','Travel together.')]:
 add('google',None,'creative_test',label,text,action='not applicable',section='Future static artwork proposal, not a console field',deps=['Optional future still adaptation; no generation or upload proposed','No platform text-field cap applies to graphic pixels'],refs=['google_graphics'])
add('google','en-GB','test_variant','Short description','Your bookings, tickets and daily plans together. Saved tickets work offline.',80,section='Store listings > Experiments > Localized > Variant',deps=['Optional future experiment only; not recommended launch copy'],refs=['google_experiments'])
for sub in subjects:
 for suffix in ['', '_1206x2622']:
  p=ROOT/f'docs/mockups/app-store-screenshots-v1/final/{sub:02}-{subjects[sub][0]}{suffix}.png'
  asset_record('apple','all','inventory','Unassigned source inventory',p,'iPhone source '+('medium' if suffix else 'large'),subject=sub,required=False,status='Existing source; no upload instruction',active=False)

(OUT/'listing-fields.json').write_text(json.dumps(fields,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
(OUT/'asset-map.json').write_text(json.dumps(dict(research_date=DATE,status='proposed/unapproved',required_semantics='Required within the proposed page configuration; universal platform minimums are separately documented in REPORT.md. Optional large-screen promotion work is marked false.',orders=orders,assets=assets),indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
(OUT/'sources.json').write_text(json.dumps(S,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

# Full exact copy is rendered from the saved record, never hand-retyped.
appendix=['## Complete field values and computed counts\n','All strings below are exact. Each text file has UTF-8 encoding, LF paragraph breaks and no trailing newline. Long descriptions are complete. CPP title, subtitle and description inherit the same locale\'s default Apple listing and are not separately editable. Values in administrative rows remain blocked. A count marked N/A means no verified cap, not an invented unlimited allowance.\n']
for store in ['apple','google']:
 for loc in ['en-US','en-GB','en-AU',None]:
  subset=[f for f in fields if f['store']==store and f['locale']==loc and isinstance(f['value'],str)]
  if not subset:continue
  appendix.append(f'### {store.title()} / {loc or "shared settings"}\n')
  for f in subset:
   cap=f"{f['limit']} {f['limit_unit']}" if f['limit'] is not None else 'No verified cap / selection or URL'
   appendix += [f"#### {f['page_type']} — {f['field_label']}"+(f" — {f['upload_order']}" if f['upload_order'] else '')+'\n',f"Record `{f['id']}`. Action: **{f['action']}**. {f['character_count']} characters; {f['utf8_byte_count']} UTF-8 bytes; limit {cap}; remaining {f['remaining_capacity'] if f['remaining_capacity'] is not None else 'N/A'}; **{f['validation']}**. [Exact text]({f['source_file']}).\n",f"<!-- COPY:{f['id']} -->\n```text\n{f['value']}\n```\n<!-- END_COPY:{f['id']} -->\n"]
appendix.append('## Consolidated text count table\n')
appendix.append('| Record / locale | Field | Exact text or full-value link above | Characters | UTF-8 bytes | Limit / unit | Remaining | Result |\n|---|---|---|---:|---:|---|---:|---|')
for f in fields:
 if not isinstance(f['value'],str):continue
 display=f['value'].replace('\n',' ⏎ ') if len(f['value'])<180 else '[Full exact field]('+f['source_file']+')'
 appendix.append('| '+' | '.join([f['id'],f['field_label'],display,str(f['character_count']),str(f['utf8_byte_count']),str(f['limit'])+' '+str(f['limit_unit']) if f['limit'] is not None else 'Unverified / N/A',str(f['remaining_capacity']) if f['remaining_capacity'] is not None else 'N/A',f['validation']])+' |')
appendix.append('## Existing screenshot captions — unchanged artwork\n')
appendix.append('| Subject | Exact headline (⏎ means artwork line break) | Supporting caption | Purchase tag | Headline chars | Caption chars |\n|---|---|---|---|---:|---:|')
for sub,(_,h,c,alt) in subjects.items():
 tag='2 free, then a pass' if sub==4 else 'With a pass' if sub==6 else 'Share it with a pass (in supporting caption)' if sub==9 else 'None'
 appendix.append('| '+ ' | '.join([str(sub),h.replace('\n',' ⏎ '),c,tag,str(len(h)),str(len(c))])+' |')
appendix.append('Artwork captions have no separate console text-field cap. These are transcriptions for asset review, not instructions to regenerate images. Graphic caption counts include the transcribed line breaks; console copy counts above derive from exact text files.\n')
appendix.append('## Non-text fields, omissions and blocked administrative values\n')
appendix.append('| Record | Store / locale / page | Field | Action | Exact value | Dependency |\n|---|---|---|---|---|---|')
for f in fields:
 if isinstance(f['value'],str) or f['asset_path'] or f['device_bucket']:continue
 appendix.append('| '+ ' | '.join([f['id'],f"{f['store']} / {f['locale'] or 'shared'} / {f['page_type']}",f['field_label'],f['action'],json.dumps(f['value'],ensure_ascii=False),'; '.join(f['dependencies']).replace('|','/')])+' |')
report=(OUT/'report-research.md').read_text(encoding='utf-8')+'\n\n'+'\n'.join(appendix)
def absolute_link(m):
 target=m.group(1)
 if target.startswith(('http://','https://','/','#')):return m.group(0)
 return ']('+str((OUT/target).resolve())+')'
report=re.sub(r'\]\(([^)]+)\)',absolute_link,report)
(OUT/'REPORT.md').write_text(report,encoding='utf-8')
copy_index=['# Paste-ready copy index\n','UTF-8 files without BOM or trailing newline. Use matching store, locale and page. All values are proposed/unapproved; tests and creative proposals are excluded from launch population.\n','| Store | Locale | Page | Field | Exact file |\n|---|---|---|---|---|']
for f in fields:
 if f['source_file']:copy_index.append('| '+' | '.join([f['store'],f['locale'] or 'shared',f['page_type'],f['field_label'],f"[Text]({f['source_file']})"] )+' |')
(OUT/'copy/README.md').write_text('\n'.join(copy_index)+'\n')
print(json.dumps({'fields':len(fields),'assets':len(assets),'copy_files':sum(isinstance(f['value'],str) for f in fields),'over_limit':[f['id'] for f in fields if f['validation']=='FAIL']},indent=2))
