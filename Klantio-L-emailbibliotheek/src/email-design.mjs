export {brand,escapeHtml,substitute,validateUrl,eyebrow,button,infoCard,welcomeBody} from '../../../Instrecteur/Klantio-emailbibliotheek/src/transactional-design.mjs';
import {htmlEmail as sharedHtml,textEmail as sharedText} from '../../../Instrecteur/Klantio-emailbibliotheek/src/transactional-design.mjs';
export const htmlEmail=(mail,options={})=>sharedHtml({...mail,product:'leerling'},options);
export const textEmail=(mail,options={})=>sharedText({...mail,product:'leerling'},options);
