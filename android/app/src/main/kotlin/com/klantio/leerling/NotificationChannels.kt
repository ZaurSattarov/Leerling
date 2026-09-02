package com.klantio.leerling

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log

/**
 * Canonical Android notification channels voor de Leerling-app.
 *
 * Root cause (2026-09-01, bewezen via emulator dumpsys): de backend/FCM-payload
 * verwijst voor veel notificatietypes expliciet naar een `android.notification.channel_id`
 * (bv. `klantio_lessen`). Op Android 8+ (API 26+) wordt een tray-notification niet
 * getoond als het opgegeven kanaal niet bestaat. iOS ontving dezelfde push wel zichtbaar,
 * Android kreeg de FCM-message technisch binnen maar toonde niets, omdat deze kanalen
 * nooit werden aangemaakt. Dit bestand lost uitsluitend die ontbrekende OS-integratie op
 * -- geen wijziging aan wélke notificaties worden verstuurd of wat erin staat.
 *
 * Kanalen zijn 1-op-1 afgeleid van de bestaande canonical `channel_id`-waarden die de
 * backend al verstuurt (zie Notificatie-Architectuur.md); niet opnieuw ontworpen.
 */
object NotificationChannels {
    private const val TAG = "KlantioChannels"

    const val CHANNEL_LESSEN = "klantio_lessen"
    const val CHANNEL_FINANCIEEL = "klantio_financieel"
    const val CHANNEL_ALGEMEEN = "klantio_algemeen"

    // Live Aankomst (2026-09-02): eigen kanaal, gescheiden van CHANNEL_LESSEN, zodat een
    // leerling Live Aankomst-meldingen afzonderlijk kan beheren zonder gewone lesmeldingen
    // uit te zetten. Zelfde canonical channel_id als push_logic.ts::androidChannelFor.
    const val CHANNEL_LIVE_AANKOMST = "klantio_live_aankomst"

    private val CHANNEL_NAMES = mapOf(
        CHANNEL_LESSEN to "Lessen",
        CHANNEL_FINANCIEEL to "Financieel",
        CHANNEL_ALGEMEEN to "Algemeen",
        CHANNEL_LIVE_AANKOMST to "Live aankomst",
    )

    /**
     * Idempotent: veilig om bij elke app-start / MethodChannel-call opnieuw aan te roepen.
     * - kanaal ontbreekt -> aanmaken met IMPORTANCE_HIGH
     * - kanaal bestaat met lagere importance -> verwijderen + opnieuw aanmaken als HIGH
     *   (een bestaand kanaal met een lagere importance kan niet in-place worden verhoogd;
     *   Android negeert `setImportance` na creatie)
     * - kanaal bestaat al met HIGH -> ongemoeid laten (behoudt eventuele gebruikersinstellingen)
     */
    @JvmStatic
    fun ensureCreated(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            // Notification channels bestaan niet vóór Android 8 (API 26).
            return
        }

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        if (manager == null) {
            Log.w(TAG, "NotificationManager niet beschikbaar, kan channels niet aanmaken")
            return
        }

        for ((id, name) in CHANNEL_NAMES) {
            val existing = manager.getNotificationChannel(id)
            if (existing == null) {
                createHighImportanceChannel(manager, id, name)
                Log.d(TAG, "channel $id aangemaakt importance=${NotificationManager.IMPORTANCE_HIGH}")
            } else if (existing.importance < NotificationManager.IMPORTANCE_HIGH) {
                manager.deleteNotificationChannel(id)
                createHighImportanceChannel(manager, id, name)
                Log.d(
                    TAG,
                    "channel $id had importance=${existing.importance}, opnieuw aangemaakt " +
                        "importance=${NotificationManager.IMPORTANCE_HIGH}",
                )
            } else {
                Log.d(TAG, "channel $id importance=${existing.importance} (behouden)")
            }
        }
    }

    private fun createHighImportanceChannel(manager: NotificationManager, id: String, name: String) {
        val channel = NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH)
        manager.createNotificationChannel(channel)
    }
}
