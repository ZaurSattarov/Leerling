package com.klantio.leerling

import android.app.Application
import android.util.Log

/**
 * Custom Application zodat de canonical notificatiekanalen zo vroeg mogelijk bestaan --
 * al vóór MainActivity/Flutter opstart, en ook bij bv. een background FCM-delivery terwijl
 * de app niet in de foreground draait.
 */
class KlantioLeerlingApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Log.d("KlantioChannels", "Application.onCreate start")
        NotificationChannels.ensureCreated(this)
    }
}
