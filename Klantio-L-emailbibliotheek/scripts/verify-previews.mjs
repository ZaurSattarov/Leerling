import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {catalog,example} from '../src/catalogus.mjs';
import {htmlEmail,substitute} from '../src/email-design.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const require=createRequire(import.meta.url);
const {chromium}=require(path.join(process.env.KLANTIO_NODE_MODULES,'playwright'));
const sharp=require(path.join(process.env.KLANTIO_NODE_MODULES,'sharp'));
const out=path.join(root,'qa');fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
const browser=await chromium.launch({headless:true,channel:'msedge'});
const page=await browser.newPage();const results=[];
try{
 for(const m of catalog){
  const url=pathToFileURL(path.join(root,`mails/${m.slug}/preview.html`)).href;
  const checks=[];
  for(const [label,width] of [['desktop',900],['mobiel',390],['smal',320]]){
   await page.setViewportSize({width,height:1000});await page.goto(url);
   const state=await page.evaluate(()=>({overflow:document.documentElement.scrollWidth>innerWidth,images:[...document.images].every(i=>i.complete&&i.naturalWidth>0&&i.alt),h1:document.querySelectorAll('h1').length,unresolved:document.body.innerHTML.includes('{{'),scripts:document.scripts.length,cta:[...document.querySelectorAll('.primary-button')].every(a=>a.getBoundingClientRect().height>=44)}));
   if(state.overflow||!state.images||state.h1!==1||state.unresolved||state.scripts||!state.cta)throw Error(`${m.id}/${label}: ${JSON.stringify(state)}`);
   if(label!=='smal')await page.screenshot({path:path.join(out,'screenshots',`${String(m.id).padStart(2,'0')}-${label}.png`),fullPage:true});
   checks.push(label);
  }
  await page.route('**/*.png',route=>route.abort());await page.reload();
  const fallback=await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth&&!!document.querySelector('h1').textContent&&document.querySelectorAll('.primary-button').length>=1);
  if(!fallback)throw Error(`${m.id}: afbeeldingen-uit`);checks.push('afbeeldingen-uit');await page.unrouteAll();
  await page.emulateMedia({colorScheme:'dark'});await page.reload();
  if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth))throw Error(`${m.id}: dark media overflow`);
  checks.push('browser-dark-media');await page.emulateMedia({colorScheme:'light'});
  const stress={...example,student_name:'Alexandra & Mohamed '.repeat(15)+'<test>',school_name:'Rijschool <Demo> & Partners '.repeat(10),instructor_name:'ExtreemlangeNaamZonderSpaties'.repeat(8),cancellation_note:'',leerling_naam:'Alexandra & Mohamed van der Lange Voorbeeldachternaam '.repeat(8)+'<test>',medewerker_naam:'ExtreemlangeNaamZonderSpaties'.repeat(8),rijschool_naam:'Rijschool <Demo> & Partners '.repeat(10),toelichting:'',action_url:'https://example.invalid/demo',website_url:'https://example.invalid',support_url:'mailto:info@klantio.com',getting_started_url:'https://example.invalid/start',preferences_url:'https://example.invalid/preferences',logo_url:pathToFileURL(path.join(root,'assets/klantio-wordmark.png')).href,illustration_url:pathToFileURL(path.join(root,`assets/${m.theme}.png`)).href};
  await page.setContent(substitute(htmlEmail(m),stress));
  if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth))throw Error(`${m.id}: lange waarden lopen over`);checks.push('lange-namen-speciale-tekens-lege-toelichting');
  results.push({id:m.id,checks,status:'PASS'});
  if(m.id%10===0)console.log(`${m.id}/36 gecontroleerd`);
 }
 await page.setViewportSize({width:1400,height:1000});await page.goto(pathToFileURL(path.join(root,'index.html')).href);
 await page.locator('#list .item').first().waitFor();
 if(await page.locator('#list .item').count()!==36)throw Error('Catalogus mist mails');
 await page.locator('#category').selectOption('betalingen');if(await page.locator('#list .item').count()!==6)throw Error('Categoriefilter defect');
 await page.locator('#category').selectOption('');await page.locator('#search').fill('maandoverzicht');if(await page.locator('#list .item').count()!==1)throw Error('Zoekfilter defect');
 await page.locator('#list .item').click();if(!page.url().endsWith('#36'))throw Error('Selectie defect');await page.locator('#search').fill('');await page.goto(pathToFileURL(path.join(root,'index.html')).href+'#1');await page.screenshot({path:path.join(out,'catalogus.png'),fullPage:true});
 await page.goto(pathToFileURL(path.join(root,'voorkeuren.html')).href);await page.locator('input[name="planning"]').check();await page.locator('button[type="submit"]').click();if(!(await page.locator('#status').textContent()).includes('opgeslagen'))throw Error('Demo-voorkeuren defect');
 await page.screenshot({path:path.join(out,'voorkeuren.png'),fullPage:true});
 const report={date:'2026-10-20',browser:'Microsoft Edge via Playwright',templates:results.length,renderChecks:results.reduce((n,r)=>n+r.checks.length,0),results,catalogue:'PASS: 36 items, filter, zoeken, selectie',preferencesDemo:'PASS: lokale opslag; geen accountwijziging',notTested:['Gmail inbox','Klassieke Outlook','Apple Mail inbox','Automatische inbox-darkmode','Live triggers','Live Auth/support/push/IMAP-regressies','Staging database','Resend-integratie']};
 fs.writeFileSync(path.join(out,'resultaten.json'),JSON.stringify(report,null,2));
 const buffers=[];for(const m of catalog){const thumb=await sharp(path.join(out,'screenshots',`${String(m.id).padStart(2,'0')}-desktop.png`)).extract({left:150,top:35,width:600,height:1000}).resize(240,400).png().toBuffer();buffers.push(thumb);}
 for(const [category]of Object.entries(Object.groupBy(catalog,m=>m.category))){const mails=catalog.filter(m=>m.category===category);const rows=Math.ceil(mails.length/3);const sheet=sharp({create:{width:750,height:rows*435,channels:3,background:'#E3E7ED'}});await sheet.composite(mails.map((m,i)=>({input:buffers[m.id-1],left:5+(i%3)*250,top:20+Math.floor(i/3)*435}))).png().toFile(path.join(out,`contact-${category}.png`));}
 console.log(`PASS: ${report.templates} e-mails, ${report.renderChecks} render-/inhoudcontroles, catalogus en voorkeurendemo.`);
}finally{await browser.close();}
