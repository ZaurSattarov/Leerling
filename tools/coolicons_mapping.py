"""Vertaaltabel Material Icons -> CoolIcons (lib/core/constants/cool_icons.dart).

Gebruikt door tools/apply_coolicons.py om de hele app op de coolicons-set te
zetten (zelfde set als de Instructeur-app). Merk-iconen (bv. Facebook) blijven
bewust Material: coolicons heeft geen merklogo's.
"""
MAP = {
 # navigatie / chevrons
 'chevron_right_rounded':'chevronRight','arrow_forward_rounded':'arrowRightMd','arrow_back_rounded':'chevronLeft',
 'arrow_upward_rounded':'arrowUpMd','arrow_downward_rounded':'arrowDownMd','swap_horiz_rounded':'arrowLeftRight',
 'close_rounded':'closeMd','add_rounded':'addPlus','remove_rounded':'removeMinus','add_circle_outline_rounded':'addPlusCircle',
 'refresh_rounded':'arrowReload02','download_rounded':'download','send_rounded':'paperPlane',
 # status / feedback
 'wifi_off_rounded':'cloudOff','cloud_off_rounded':'cloudOff','info_outline_rounded':'info','error_outline_rounded':'circleWarning',
 'warning_amber_rounded':'triangleWarning','warning_rounded':'triangleWarning','check_rounded':'check',
 'check_circle_rounded':'circleCheck','check_circle_outline_rounded':'circleCheck','task_alt_rounded':'circleCheck',
 'cancel_outlined':'closeCircle','block':'stopSign','search_off_rounded':'searchMagnifyingGlass',
 'broken_image_outlined':'image01','videocam_off_rounded':'image02','pause_circle_outline':'pauseCircle',
 # tijd / agenda
 'event_outlined':'calendar','event_rounded':'calendar','event_available_outlined':'calendarCheck','event_available_rounded':'calendarCheck',
 'event_busy_rounded':'calendarClose','event_busy_outlined':'calendarClose','calendar_today_outlined':'calendar',
 'calendar_month_rounded':'calendarDays','schedule_outlined':'clock','schedule_rounded':'clock','access_time_rounded':'clock',
 'timer_outlined':'timer','history_rounded':'clock','alarm_rounded':'alarm','alarm_on_rounded':'alarm','timeline_rounded':'chartLine',
 # locatie / rijden
 'location_on_outlined':'mapPin','location_on_rounded':'mapPin','map_outlined':'map','near_me_rounded':'navigation',
 'directions_rounded':'navigation','directions_outlined':'navigation','route_rounded':'navigation',
 'directions_car_rounded':'carAuto','directions_car_outlined':'carAuto','directions_car_filled_rounded':'carAuto',
 # communicatie
 'email_outlined':'mail','mail_outline_rounded':'mail','phone_outlined':'phone','phone_rounded':'phone','call_outlined':'phone',
 'forum_outlined':'chatConversation','chat_bubble_outline_rounded':'chat','chat_rounded':'chatCircleDots','chat_outlined':'chat',
 'add_comment_outlined':'chatAdd','headset_mic_outlined':'headphones','rate_review_outlined':'chatDots','rate_review_rounded':'chatDots',
 'notifications_none_rounded':'bell','notifications_rounded':'bell','notifications_off_outlined':'bellOff',
 # documenten / geld
 'receipt_long_rounded':'fileDocument','receipt_long_outlined':'fileDocument','article_rounded':'fileDocument',
 'assignment_rounded':'fileEdit','notes_rounded':'note','edit_note_rounded':'noteEdit','menu_book_rounded':'bookOpen',
 'fact_check_rounded':'listChecklist','fact_check_outlined':'listChecklist','checklist_rounded':'listChecklist',
 'payments_outlined':'creditCard01','euro_rounded':'creditCard01','account_balance_rounded':'building01',
 'inventory_2_rounded':'archive','inventory_2_outlined':'archive','layers_outlined':'layers',
 # mensen / account
 'person_outline_rounded':'user01','person_outline':'user01','person_rounded':'user01','person_off_outlined':'userClose',
 'badge_outlined':'userCardId','cake_outlined':'gift','school_rounded':'bookOpen','school_outlined':'bookOpen',
 'psychology_alt_rounded':'bulb','lightbulb_rounded':'bulb','quiz_outlined':'circleHelp',
 # beveiliging / instellingen
 'lock_outline_rounded':'lock','lock_reset_rounded':'lockOpen','key_outlined':'lock','shield_outlined':'shieldCheck',
 'privacy_tip_rounded':'shieldCheck','privacy_tip_outlined':'shieldCheck','settings_outlined':'settings',
 'app_settings_alt_outlined':'settings','language_outlined':'globe','logout_rounded':'logOut',
 'visibility_outlined':'show','visibility_off_outlined':'hide','delete_forever_rounded':'trashFull','delete_outline_rounded':'trashEmpty',
 # media
 'photo_camera_outlined':'image02','camera_alt_rounded':'image02','photo_library_outlined':'image01',
 'qr_code_scanner_rounded':'scanLine','flash_on_rounded':'bulb','flash_off_rounded':'bulb','keyboard_rounded':'text',
 # voortgang / prestaties
 'trending_up_rounded':'trendingUp','trending_down_rounded':'trendingDown','trending_flat_rounded':'arrowRightMd',
 'bar_chart_rounded':'chartBarVertical01','donut_large_rounded':'chartPie','flag_rounded':'flag','flag_circle_rounded':'flag',
 'star_rounded':'star','star_outline_rounded':'star','stars_rounded':'star','grade_rounded':'star',
 'emoji_events_rounded':'star','emoji_events_outlined':'star',
 'storefront_rounded':'building03','store_outlined':'building03',
}
