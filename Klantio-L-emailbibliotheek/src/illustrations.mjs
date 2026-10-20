const navy='#1E2635',red='#D72F62',gray='#CBD2DC';
const line=(d,color=navy,width=7)=>`<path d="${d}" stroke="${color}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>`;
const rect=(x,y,w,h,fill='white',r=16)=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}"/>`;
const text=(x,y,t,size=22,color=navy)=>`<text x="${x}" y="${y}" fill="${color}" font-family="Arial, sans-serif" font-size="${size}" font-weight="700">${t}</text>`;
function person(x,ground,skin='#D59670',shirt=red,variant=0,scale=.95){return `<g aria-label="Volledige leerling met twee handen, benen en schoenen" transform="translate(${x} ${ground-434*scale}) scale(${scale})">
  <!-- Onderlichaam: twee afzonderlijk zichtbare broekspijpen en schoenen. -->
  <path d="M-58 250H58L56 304L47 411H15L5 302H-5L-15 411H-48L-59 302Z" fill="${navy}"/>
  ${line('M0 275V300M-29 315L-27 393M30 315L29 393','#536075',3)}
  <path d="M-49 404H-15L-13 427Q-13 434-22 434H-68Q-76 434-74 426Q-72 416-54 414Z" fill="${navy}"/>
  <path d="M15 404H48L54 414Q73 416 75 426Q77 434 68 434H23Q14 434 13 427Z" fill="${navy}"/>
  ${line('M-69 429H-20M21 429H69','#8793A4',3)}
  <!-- Armen lopen vanaf de mouwen naar echte handpalmen, buiten het lijf. -->
  <path d="M-77 172Q-92 204-92 241L-85 262L-68 253L-68 232L-54 187Z" fill="${skin}"/>
  <path d="M77 172Q92 204 92 241L85 262L68 253L68 232L54 187Z" fill="${skin}"/>
  <path d="M-55 127Q-73 128-81 149L-89 177L-58 193L-42 151M55 127Q73 128 81 149L89 177L58 193L42 151" fill="${shirt}"/>
  <path d="M-50 128L-20 120H20L50 128L60 255Q31 277-1 274Q-32 277-60 255Z" fill="${shirt}"/>
  <path d="M-17 102H17V132L0 147L-17 132Z" fill="${skin}"/>
  <path d="M-21 122L0 146L-14 161L-31 132M21 122L0 146L14 161L31 132" fill="${shirt===navy?'#536075':'#B42450'}"/>
  ${line('M0 149V173',shirt===navy?'#8793A4':'#B42450',3)}
  <circle cx="0" cy="158" r="2" fill="white"/>
  <!-- Handpalmen, duimen en subtiele vingers. -->
  <path d="M-88 239Q-97 244-96 258L-94 277Q-93 284-88 282L-85 269L-86 283Q-84 289-79 284L-77 267L-77 280Q-75 285-71 280L-70 261L-64 253Q-61 247-66 244Q-70 242-75 250L-77 240Z" fill="${skin}"/>
  <path d="M88 239Q97 244 96 258L94 277Q93 284 88 282L85 269L86 283Q84 289 79 284L77 267L77 280Q75 285 71 280L70 261L64 253Q61 247 66 244Q70 242 75 250L77 240Z" fill="${skin}"/>
  ${line('M-86 259L-88 275M86 259L88 275','#986044',1.5)}
  <!-- Hoofd en vriendelijk gezicht. -->
  <ellipse cx="-43" cy="67" rx="8" ry="13" fill="${skin}"/><ellipse cx="43" cy="67" rx="8" ry="13" fill="${skin}"/>
  <ellipse cy="60" rx="43" ry="52" fill="${skin}"/>
  <path d="M-42 60C-57 14-24-13 9 1C47-6 59 31 41 59L32 30C8 44-12 40-29 30L-34 63Z" fill="${navy}"/>
  ${line('M-19 62H-17M17 62H19',navy,4.5)}${line('M0 66L-3 78H3','#986044',2)}${line('M-11 88Q1 98 16 86',navy,3)}
  ${variant?line('M-35 53H-8V70H-33ZM8 53H35V70H10M-8 59H8',navy,2.5):''}
 </g>`;}
function calendar(){return rect(451,106,402,312)+rect(451,106,402,65,navy)+text(478,148,'Jouw planning',24,'white')+line('M489 216H540M489 267H540M489 318H540M489 369H540',gray,8)+rect(575,192,241,46,red,9)+rect(575,249,170,46,navy,9)+rect(575,306,241,46,red,9)+line('M599 214H781M599 271H719M599 328H779','white',5);}
function car(){return `<g transform="translate(482 318)"><path d="M0 94L15 47L62 31L96-18H228L270 32L310 48L324 94Z" fill="${red}"/><path d="M107-7H166V34H78ZM179-7H220L254 34H179Z" fill="${navy}"/>${rect(10,65,30,14,'white',5)}${rect(282,65,30,14,'white',5)}<circle cx="77" cy="95" r="28" fill="${navy}"/><circle cx="251" cy="95" r="28" fill="${navy}"/><circle cx="77" cy="95" r="12" fill="#CBD2DC"/><circle cx="251" cy="95" r="12" fill="#CBD2DC"/>${rect(139,-39,47,24,'white',5)}${text(155,-20,'L',20)}</g>`;}
function sheet(title='Overzicht'){return rect(486,95,304,365)+rect(486,95,304,61,navy)+text(512,135,title,23,'white')+line('M519 194H752M519 224H691M519 267H744M519 310H710M519 353H752M519 397H699',gray,8);}
function phone(x,y,kind='home',scale=1){return `<g transform="translate(${x} ${y}) scale(${scale})">${rect(0,0,134,240,navy,22)}${rect(9,10,116,220,'white',15)}${rect(43,10,48,8,navy,4)}${text(23,49,'Klantio L',17)}${rect(22,67,90,56,red,8)}${kind==='betaling'?text(53,107,'€',35,'white'):line('M33 86H99M33 103H84','white',5)}${line('M25 148H108M25 173H94M25 198H106',gray,6)}</g>`;}
function clock(x=815,y=365){return `<circle cx="${x}" cy="${y}" r="65" fill="white"/><circle cx="${x}" cy="${y}" r="49" stroke="${navy}" stroke-width="8"/>`+line(`M${x} ${y-30}V${y}L${x+24} ${y+17}`,red,7);}
function check(x,y){return `<circle cx="${x}" cy="${y}" r="48" fill="${red}"/>`+line(`M${x-21} ${y}L${x-5} ${y+16}L${x+23} ${y-18}`,'white',8);}
const scenes={
 welkom:()=>phone(300,253,'home',.5)+car()+rect(536,126,283,81)+text(562,159,'Welkom bij Klantio L',21)+line('M563 184H779',gray,6),
 'les-gepland':()=>person(436,530,'#986044',navy,1,.78)+`<g transform="translate(140 0)">${car()}</g>`+rect(534,105,293,116)+text(558,143,'Jouw rijles',23)+line('M560 175H734M560 197H688',gray,6)+check(829,169),
 'les-verplaatst':()=>calendar()+clock()+`<g transform="translate(646 264)"><circle r="47" fill="${red}"/>${line('M-25-8H25L12-21M25 12H-25L-12 25','white',7)}</g>`,
 'les-geannuleerd':()=>calendar()+car()+`<circle cx="825" cy="176" r="55" fill="${navy}"/>`+line('M805 156L845 196M845 156L805 196','white',9),
 lesherinnering:()=>phone(300,253,'home',.5)+car()+clock(692,188),
 voortgang:()=>sheet('Mijn voortgang')+rect(520,214,232,22,'#E3E7ED',10)+rect(520,214,151,22,red,10)+line('M526 278L541 292L562 265M526 322L541 336L562 309',red,6)+line('M590 281H741M590 325H718',gray,7)+check(804,401),
 examen:()=>car()+rect(510,95,278,229)+rect(510,95,278,54,navy)+text(534,132,'Praktijkexamen',22,'white')+line('M542 185H744M542 220H710M542 256H745',gray,7)+rect(811,111,81,98)+line('M831 137H874M831 160H866M831 183H874',red,6),
 geslaagd:()=>car()+check(693,194)+`<circle cx="420" cy="211" r="29" stroke="${navy}" stroke-width="9"/><path d="M420 240V285H439M420 264H438" stroke="${navy}" stroke-width="10" stroke-linejoin="round"/>`+line('M509 107L520 121M839 224L852 215M604 274L610 287',red,8)+line('M835 111L823 126M475 297L487 292',navy,6),
 betaling:()=>phone(540,110,'betaling',1.45)+rect(768,173,153,112)+text(792,216,'Factuur',23)+text(815,254,'€',34,red)+line('M795 303H889M795 328H860',gray,7),
 beveiliging:()=>phone(523,117,'home',1.4)+`<path d="M809 195L891 226V285C891 343 809 377 809 377C809 377 727 343 727 285V226Z" fill="${navy}"/>`+rect(782,265,55,52,red,8)+line('M792 265V251C792 225 827 225 827 251V265','white',6)+line('M810 284V299','white',5),
};
export const themes=Object.keys(scenes);
export function illustration(theme){if(!scenes[theme])throw Error(theme);return `<svg xmlns="http://www.w3.org/2000/svg" width="1040" height="580" viewBox="0 0 1040 580" fill="none"><title>Klantio L — ${theme}</title><desc>Volledige leerling met handen, benen en schoenen bij ${theme}; originele Klantio L-vectorillustratie.</desc>${rect(0,0,1040,580,'#F0F2F5',28)}<path d="M124 492C61 352 126 166 301 120C497 68 792 83 906 254C968 346 937 451 888 492H124Z" fill="#E3E7ED"/>${line('M140 536H925','#CBD2DC',3)}${person(245,530,theme==='beveiliging'?'#986044':'#D59670',red,theme==='voortgang'?1:0,.91)}${scenes[theme]()}${line('M393 102V124M382 113H404M932 425V447M921 436H943',red,5)}</svg>`;}
