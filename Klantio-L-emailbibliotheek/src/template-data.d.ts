// Presentatievelden voor de serverrenderer. Controleer brondata en toegangsrechten vóór formattering.
export interface CommonLinks { action_url: string; website_url: string; logo_url: string; illustration_url: string; support_url: string; preferences_url?: string; getting_started_url?: string; }
export interface Email01Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  getting_started_url: string;
  illustration_url: string;
  support_url: string;
}
export interface Email02Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  student_email: string;
  action_url: string;
  illustration_url: string;
  valid_until: string;
  support_url: string;
}
export interface Email03Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  student_email: string;
  valid_until: string;
  support_url: string;
}
export interface Email04Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  student_email: string;
  changed_at: string;
  support_url: string;
}
export interface Email05Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  old_email: string;
  new_email: string;
  changed_at: string;
  support_url: string;
}
export interface Email06Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  student_email: string;
  effective_date: string;
  support_url: string;
}
export interface Email07Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  lesson_date: string;
  lesson_start: string;
  lesson_end: string;
  instructor_name: string;
  lesson_location?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email08Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  old_lesson_moment: string;
  new_lesson_moment: string;
  instructor_name: string;
  lesson_location?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email09Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  lesson_moment: string;
  old_location?: string;
  new_location?: string;
  instructor_name: string;
  support_url: string;
  preferences_url: string;
}
export interface Email10Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  lesson_date: string;
  lesson_start: string;
  lesson_end: string;
  instructor_name: string;
  lesson_location?: string;
  cancellation_note?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email11Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  lesson_date: string;
  lesson_start: string;
  lesson_end: string;
  instructor_name: string;
  lesson_location?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email12Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  lesson_date: string;
  lesson_start: string;
  lesson_end: string;
  instructor_name: string;
  lesson_location?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email13Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  lesson_moment: string;
  instructor_name: string;
  lesson_location?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email14Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  lesson_moment: string;
  instructor_name: string;
  support_url: string;
  preferences_url: string;
}
export interface Email15Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  period: string;
  availability_summary: string;
  support_url: string;
  preferences_url: string;
}
export interface Email16Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  lesson_moment: string;
  instructor_name: string;
  evaluation_summary?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email17Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  changed_at: string;
  progress_summary: string;
  support_url: string;
  preferences_url: string;
}
export interface Email18Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  milestone_name: string;
  milestone_date: string;
  support_url: string;
  preferences_url: string;
}
export interface Email19Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  school_name: string;
  package_name: string;
  remaining_lessons: string;
  support_url: string;
  preferences_url: string;
}
export interface Email20Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  school_name: string;
  package_name: string;
  support_url: string;
  preferences_url: string;
}
export interface Email21Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  month: string;
  progress_summary: string;
  support_url: string;
  preferences_url: string;
}
export interface Email22Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  exam_type: string;
  exam_moment: string;
  exam_location?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email23Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  old_exam_moment: string;
  exam_moment: string;
  old_exam_location?: string;
  exam_location?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email24Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  exam_type: string;
  exam_moment: string;
  exam_location?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email25Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  exam_type: string;
  exam_date: string;
  exam_result: string;
  support_url: string;
  preferences_url: string;
}
export interface Email26Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  exam_type: string;
  exam_date: string;
  support_url: string;
  preferences_url: string;
}
export interface Email27Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  school_name: string;
  action_url: string;
  illustration_url: string;
  invoice_number: string;
  invoice_amount: string;
  invoice_due_date: string;
  payment_status: string;
  support_url: string;
  preferences_url: string;
}
export interface Email28Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  school_name: string;
  invoice_number: string;
  invoice_amount: string;
  invoice_due_date: string;
  payment_status: string;
  support_url: string;
  preferences_url: string;
}
export interface Email29Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  school_name: string;
  action_url: string;
  illustration_url: string;
  invoice_number: string;
  invoice_amount: string;
  invoice_due_date: string;
  payment_status: string;
  support_url: string;
  preferences_url: string;
}
export interface Email30Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  school_name: string;
  action_url: string;
  illustration_url: string;
  invoice_number: string;
  invoice_amount: string;
  paid_at: string;
  payment_method?: string;
  support_url: string;
  preferences_url: string;
}
export interface Email31Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  school_name: string;
  invoice_number: string;
  invoice_amount: string;
  changed_at: string;
  support_url: string;
  preferences_url: string;
}
export interface Email32Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  school_name: string;
  invoice_number: string;
  adjustment_type: string;
  adjustment_reference: string;
  invoice_amount: string;
  changed_at: string;
  support_url: string;
  preferences_url: string;
}
export interface Email33Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  school_name: string;
  action_url: string;
  illustration_url: string;
  instructor_name: string;
  valid_until: string;
  support_url: string;
}
export interface Email34Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  school_name: string;
  action_url: string;
  illustration_url: string;
  instructor_name: string;
  changed_at: string;
  support_url: string;
}
export interface Email35Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  period: string;
  lesson_count: string;
  lesson_summary: string;
  support_url: string;
  preferences_url: string;
}
export interface Email36Data extends CommonLinks {
  website_url: string;
  logo_url: string;
  student_name: string;
  action_url: string;
  illustration_url: string;
  month: string;
  completed_lessons: string;
  progress_summary: string;
  invoice_summary: string;
  support_url: string;
  preferences_url: string;
}
export interface EmailPayloadMap {
  1: Email01Data;
  2: Email02Data;
  3: Email03Data;
  4: Email04Data;
  5: Email05Data;
  6: Email06Data;
  7: Email07Data;
  8: Email08Data;
  9: Email09Data;
  10: Email10Data;
  11: Email11Data;
  12: Email12Data;
  13: Email13Data;
  14: Email14Data;
  15: Email15Data;
  16: Email16Data;
  17: Email17Data;
  18: Email18Data;
  19: Email19Data;
  20: Email20Data;
  21: Email21Data;
  22: Email22Data;
  23: Email23Data;
  24: Email24Data;
  25: Email25Data;
  26: Email26Data;
  27: Email27Data;
  28: Email28Data;
  29: Email29Data;
  30: Email30Data;
  31: Email31Data;
  32: Email32Data;
  33: Email33Data;
  34: Email34Data;
  35: Email35Data;
  36: Email36Data;
}
