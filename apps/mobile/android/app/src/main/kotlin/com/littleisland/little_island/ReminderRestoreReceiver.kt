package com.littleisland.little_island

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
import org.json.JSONArray
import java.time.LocalDateTime
import java.time.ZoneId

/** Adapter for the pinned flutter_local_notifications 22.3.3 cache format.
 * Keep wall-clock reminder times after a timezone change, discard expired slots,
 * and use inexact alarms. Re-test this adapter before upgrading the plugin.
 */
class ReminderRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in setOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED,
                Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_TIME_CHANGED)) return
        val preferences = context.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE)
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        try {
            val cached = JSONArray(preferences.getString("scheduled_notifications", "[]"))
            val future = JSONArray()
            val zone = if (intent.action == Intent.ACTION_TIMEZONE_CHANGED)
                ZoneId.of(intent.getStringExtra("time-zone") ?: ZoneId.systemDefault().id)
                else ZoneId.systemDefault()
            for (index in 0 until cached.length()) {
                val item = cached.getJSONObject(index)
                val id = item.getInt("id")
                // Only handle this app's one-shot reminder/probe IDs.
                if (id !in 1000..1055 && id !in 9101..9102) { future.put(item); continue }
                val notificationIntent = Intent(context, ScheduledNotificationReceiver::class.java)
                val oldPending = PendingIntent.getBroadcast(context, id, notificationIntent,
                    PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE)
                if (oldPending != null) alarms.cancel(oldPending)
                val trigger = LocalDateTime.parse(item.getString("scheduledDateTime")).atZone(zone).toInstant().toEpochMilli()
                if (trigger <= System.currentTimeMillis()) { oldPending?.cancel(); continue }
                item.put("timeZoneName", zone.id)
                notificationIntent.putExtra("notificationDetails", item.toString())
                val pending = PendingIntent.getBroadcast(context, id, notificationIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
                future.put(item)
            }
            preferences.edit().putString("scheduled_notifications", future.toString()).commit()
            Log.i("MizuReminders", "Restored ${future.length()} slots after ${intent.action} in ${zone.id}")
        } catch (e: Exception) {
            // Never log notification content or user data.
            Log.e("MizuReminders", "Reminder restore failed: ${e.javaClass.simpleName}")
        }
    }
}
