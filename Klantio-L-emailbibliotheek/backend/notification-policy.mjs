// Ontwikkelvoorbereiding: geen provider, databaseverbinding, cron of verzending.
import {createHash} from 'node:crypto';import {catalog} from '../src/catalogus.mjs';
export const groups=['planning','voortgang','examens','betalingen','overzichten'];
export function defaultPreferences(){return Object.fromEntries(groups.map(g=>[g,{enabled:false,mode:g==='overzichten'?'summary':'direct'}]));}
export function validatePreferences(input){if(!input||typeof input!=='object'||Array.isArray(input)||Object.keys(input).some(g=>!groups.includes(g)))throw Error('Ongeldige voorkeuren');const result=defaultPreferences();for(const[g,p]of Object.entries(input)){if(!p||Object.keys(p).some(k=>!['enabled','mode'].includes(k))||typeof p.enabled!=='boolean'||!['direct','summary'].includes(p.mode)||g==='overzichten'&&p.mode!=='summary')throw Error('Ongeldige groepsvoorkeur');result[g]={...p};}return result;}
export async function updatePreferences({userId,preferences},adapter){const session=await adapter.sessionIdentity();if(!session||session.userId!==userId||session.active!==true)throw Error('Geen toegang');const value=validatePreferences(preferences);await adapter.savePreferences({userId:session.userId,value});return value;}
const deny=reason=>({decision:'blocked',reason});
const validEmail=v=>typeof v==='string'&&v.length<=254&&/^[^\s<>@]+@[^\s<>@]+\.[^\s<>@]+$/.test(v)&&!/[\r\n]/.test(v);
export async function prepareNotification({templateId,eventId,recipientId},adapter,{now=Date.now()}={}){
 const m=catalog.find(m=>m.id===templateId);if(!m)return deny('unknown_template');if(m.auth)return deny('existing_auth_flow_only');
 if(!adapter?.loadVerifiedEvent)return deny('missing_server_adapter');
 const e=await adapter.loadVerifiedEvent(eventId);
 if(!e||e.id!==eventId||e.eventName!==m.event||e.committed!==true||e.verified!==true)return deny('unverified_event');
 if(!e.entityId||!e.dedupeKey||!Number.isInteger(e.version)||e.version<1||e.version!==e.currentVersion||e.status!==e.currentStatus)return deny('stale_or_incomplete_event');
 if(!Number.isFinite(e.occurredAt)||now-e.occurredAt>86400000||e.occurredAt>now+60000)return deny('outdated_event');
 const r=await adapter.loadRecipient(recipientId);
 if(!r||r.id!==recipientId||!validEmail(r.email))return deny('invalid_recipient');
 if(m.invite){
  if(e.inviteeRecipientId!==r.id||!e.schoolId||e.inviteTargetVerified!==true||e.inviteStatus!=='pending'||!Number.isFinite(e.inviteExpiresAt)||e.inviteExpiresAt<=now)return deny('invalid_invitation');
 }else{
  if(!r.userId||r.emailVerified!==true)return deny('unverified_email');
  if(m.category==='account'){
   if(r.userId!==e.subjectUserId)return deny('wrong_account');
   if(!r.active&&m.id!==6)return deny('inactive_account');
  }else{
   if(!r.active||!r.studentId||r.studentId!==e.studentId||!e.schoolId||e.schoolId!==r.schoolId||e.currentSchoolId!==r.schoolId)return deny('wrong_student_or_school');
   if(!['solo','team'].includes(e.productMode))return deny('invalid_product_mode');
   if(await adapter.canReadObject({userId:r.userId,studentId:r.studentId,schoolId:r.schoolId,entityId:e.entityId})!==true)return deny('object_access_denied');
  }
 }
 if(m.id===7&&e.existingLessonConfirmationAlreadySent===true)return {decision:'skip',reason:'existing_confirmation_sent'};
 if(m.id===14&&e.status!=='completed')return deny('lesson_not_completed');
 if([11,12].includes(m.id)&&(!e.reminderPolicyVerified||!Number.isFinite(e.reminderDueAt)||e.reminderDueAt>now||now-e.reminderDueAt>900000||!Number.isFinite(e.lessonStartsAt)||e.lessonStartsAt<=now))return deny('invalid_reminder_schedule');
 if(m.id===16&&(e.evaluationStatus!=='published'||e.humanApproved!==true))return deny('feedback_not_released');
 if([17,21,36].includes(m.id)&&(e.progressVerified!==true||e.progressPublished!==true))return deny('progress_not_released');
 if(m.id===18&&e.milestoneVerified!==true)return deny('milestone_not_achieved');
 if([19,20].includes(m.id)&&(!Number.isInteger(e.remainingLessons)||e.remainingLessons<0||m.id===19&&e.remainingLessons===0||m.id===20&&e.remainingLessons!==0))return deny('invalid_package_balance');
 if(m.category==='examens'&&(e.examSnapshotVerified!==true||e.examCancelled===true))return deny('unverified_exam');
 if(m.id===26&&(e.examResult!=='passed'||e.resultVerified!==true))return deny('exam_not_confirmed_passed');
 if(m.id===25&&e.resultVerified!==true)return deny('unverified_exam_result');
 if(m.category==='betalingen'){
  if(e.moneyDomain!=='school_invoice'||e.invoiceStudentId!==r.studentId||e.invoiceSchoolId!==r.schoolId||!Number.isSafeInteger(e.amountMinor)||e.amountMinor<0||e.currency!=='EUR')return deny('invalid_invoice_binding');
  if([28,29].includes(m.id)&&(!['open','partial'].includes(e.invoiceStatus)||!Number.isSafeInteger(e.outstandingMinor)||e.outstandingMinor<=0))return deny('invoice_not_open');
  if(m.id===28&&(!Number.isFinite(e.invoiceDueAt)||e.invoiceDueAt<=now))return deny('invoice_not_due_soon');
  if(m.id===29&&(!Number.isFinite(e.invoiceDueAt)||e.invoiceDueAt>=now))return deny('invoice_not_overdue');
  if([30,31].includes(m.id)||m.id===32&&e.variant==='refund'){
   if(e.paymentProviderVerified!==true||!e.paymentId||e.moneySource!=='provider')return deny('unverified_payment');
   if(m.id===30&&e.status!=='paid'||m.id===31&&(e.status!=='failed'||!['open','partial'].includes(e.invoiceStatus))||m.id===32&&e.status!=='refunded')return deny('wrong_payment_state');
  }
  if(m.id===32){
   if(!['creditnota','refund'].includes(e.variant))return deny('variant_required');
   if(e.variant==='creditnota'&&(e.moneySource!=='ledger'||e.ledgerVerified!==true||e.status!=='credit_issued'))return deny('unverified_credit_note');
  }
 }
 if(m.id===34&&e.linkConfirmed!==true)return deny('link_not_confirmed');
 if(!m.essential&&e.actorUserId===r.userId)return {decision:'skip',reason:'own_action'};
 let mode='direct';
 if(!m.essential){const p=await adapter.loadPreferences(r.userId);if(!p)return deny('preferences_unavailable');const group=m.digest?'overzichten':m.category;const pref=p[group];if(p.emailEnabled!==true||pref?.enabled!==true)return {decision:'skip',reason:'preference_disabled'};if(m.digest&&m.category!=='overzichten'&&p[m.category]?.enabled!==true)return {decision:'skip',reason:'category_disabled'};if(!['direct','summary'].includes(pref.mode))return deny('invalid_preference_mode');mode=m.digest?'summary':pref.mode;}
 if(m.digest&&(!Number.isInteger(e.itemCount)||e.itemCount<1||!e.periodKey||e.timeZone!=='Europe/Amsterdam'))return {decision:'skip',reason:'empty_digest'};
 const family=m.id===7?'existing_student_lesson_confirmation':m.id===26?'student.exam_result_registered':m.event;
 const key=createHash('sha256').update(JSON.stringify([e.schoolId??'account',r.id,family,e.dedupeKey])).digest('hex');
 return {decision:'prepared',templateId:m.id,recipientId:r.id,schoolId:e.schoolId??null,studentId:r.studentId??null,entityId:e.entityId,version:e.version,key,mode,notBefore:m.debounce?now+60000:now,variant:e.variant??null,productionEnabled:false};
}
export function coalesceLessonChanges(plans){const map=new Map(),other=[];for(const p of plans){if(p.decision!=='prepared')continue;if(![7,8,9,10,13].includes(p.templateId)){other.push(p);continue;}const k=JSON.stringify([p.schoolId,p.studentId,p.recipientId,p.entityId]);if(!map.has(k)||map.get(k).version<p.version)map.set(k,p);}return [...other,...map.values()];}
export function retryDecision(attempt,status,retryAfterSeconds=0){return {retry:Number.isInteger(attempt)&&attempt>0&&attempt<5&&(status===429||status>=500&&status<=599),delayMs:Math.max(Math.min(Math.max(retryAfterSeconds,0)*1000,3600000),Math.min(3600000,2**attempt*1000))};}
export class DemoOutbox{constructor(){this.items=new Map();}claim(plan){if(plan.decision!=='prepared')throw Error('Ongeldig plan');if(this.items.has(plan.key))return false;this.items.set(plan.key,{...plan,status:'prepared'});return true;}}
