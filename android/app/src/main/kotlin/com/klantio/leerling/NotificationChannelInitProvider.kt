package com.klantio.leerling

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.util.Log

/**
 * Startup-safeguard: ContentProviders worden door Android geïnitialiseerd vóór
 * Application.onCreate() in sommige procesopstart-paden (o.a. bepaalde background/FCM
 * process-starts). Deze provider doet geen data-werk -- uitsluitend een extra, vroege
 * garantie dat de notificatiekanalen bestaan, naast de aanroep in
 * [KlantioLeerlingApplication.onCreate].
 */
class NotificationChannelInitProvider : ContentProvider() {
    override fun onCreate(): Boolean {
        val ctx = context
        if (ctx != null) {
            Log.d("KlantioChannels", "NotificationChannelInitProvider.onCreate start")
            NotificationChannels.ensureCreated(ctx)
        }
        return true
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0
}
