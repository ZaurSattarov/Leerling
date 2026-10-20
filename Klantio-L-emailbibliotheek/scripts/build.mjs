import fs from 'node:fs';import path from 'node:path';import {fileURLToPath} from 'node:url';import {createRequire} from 'node:module';
import {catalog,categories,example} from '../src/catalogus.mjs';import {htmlEmail,textEmail,substitute} from '../src/email-design.mjs';import {themes,illustration} from '../src/illustrations.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const sharp=createRequire(import.meta.url)(path.join(process.env.KLANTIO_NODE_MODULES,'sharp'));
const write=(name,value)=>{fs.mkdirSync(path.dirname(path.join(root,name)),{recursive:true});fs.writeFileSync(path.join(root,name),value);};
const json=(name,value)=>write(name,JSON.stringify(value,null,2)+'\n');
for(const theme of themes){const svg=illustration(theme);write(`assets/${theme}.svg`,svg);await sharp(Buffer.from(svg)).png().toFile(path.join(root,`assets/${theme}.png`));}
const manifest=[];const typeLines=['// Presentatievelden voor de serverrenderer. Controleer brondata en toegangsrechten vóór formattering.','export interface CommonLinks { action_url: string; website_url: string; logo_url: string; illustration_url: string; support_url: string; preferences_url?: string; getting_started_url?: string; }'];
for(const m of catalog){
 const directory=`mails/${m.slug}`;const html=htmlEmail(m),txt=textEmail(m);
 const variables=[...new Set([...html.matchAll(/\{\{(\w+)\}\}/g)].map(x=>x[1]))];
 const values={...example,action_url:`../../actie-demo.html?mail=${m.id}`,website_url:'../../actie-demo.html?type=website',logo_url:'../../assets/klantio-wordmark.png',illustration_url:`../../assets/${m.theme}.png`,support_url:'mailto:info@klantio.com',preferences_url:'../../voorkeuren.html',getting_started_url:'../../actie-demo.html?type=eerste-stappen'};
 const metadata={...m,variables,subjectExample:substitute(m.subject,values,{html:false}),preheaderExample:substitute(m.preheader,values,{html:false}),linkStatus:'Lokale demoactie; productie-objectlink niet gekoppeld',backendStatus:'Pure voorbereiding; geen operationele nieuwe trigger'};
 write(`${directory}/email.html`,html);write(`${directory}/email.txt`,txt);write(`${directory}/onderwerp.txt`,m.subject+'\n');write(`${directory}/preview.html`,substitute(html,values));write(`${directory}/preview.txt`,substitute(txt,values,{html:false}));json(`${directory}/voorbeeld.json`,Object.fromEntries(variables.map(v=>[v,values[v]])));json(`${directory}/metadata.json`,metadata);
 const payload=variables;typeLines.push(`export interface Email${String(m.id).padStart(2,'0')}Data extends CommonLinks {\n${payload.map(v=>`  ${v}${m.optional[v]?'?':''}: string;`).join('\n')}\n}`);
 for(const variant of m.variants){const refund=variant==='refund';const v={...m,name:refund?'Je terugbetaling is bevestigd':'Je creditnota staat klaar',subject:refund?'Je terugbetaling is bevestigd':'Je creditnota staat klaar',intro:refund?'Hoi {{student_name}},<br><br>De terugbetaling bij je factuur van {{school_name}} is bevestigd. Bekijk de referentie en het bedrag hieronder.':'Hoi {{student_name}},<br><br>{{school_name}} heeft een creditnota bij je factuur geregistreerd. Dit is een administratieve correctie en geen bevestiging van geldteruggave.'};const sample={...values,adjustment_type:refund?'Terugbetaling':'Creditnota'};write(`${directory}/variant-${variant}.html`,htmlEmail(v));write(`${directory}/variant-${variant}.txt`,textEmail(v));write(`${directory}/preview-${variant}.html`,substitute(htmlEmail(v),sample));}
 manifest.push(metadata);
}
typeLines.push('export interface EmailPayloadMap {',...catalog.map(m=>`  ${m.id}: Email${String(m.id).padStart(2,'0')}Data;`),'}');write('src/template-data.d.ts',typeLines.join('\n')+'\n');json('catalogus.json',manifest);
const shell=fs.readFileSync(path.join(root,'src/catalogus-shell.html'),'utf8').replace('/*CATALOG_DATA*/',JSON.stringify(manifest).replace(/</g,'\\u003c')).replace('/*CATEGORY_DATA*/',JSON.stringify(categories));write('index.html',shell);
console.log(`Gebouwd: ${manifest.length} leerlingmails en ${themes.length} originele SVG/PNG-thema’s.`);
