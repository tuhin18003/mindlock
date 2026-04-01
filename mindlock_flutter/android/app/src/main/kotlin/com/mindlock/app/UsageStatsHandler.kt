package com.mindlock.app

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.provider.Settings
import androidx.core.content.getSystemService
import java.text.SimpleDateFormat
import java.util.*

class UsageStatsHandler(private val context: Context) {

    fun hasPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    /**
     * Returns usage data for a given date (YYYY-MM-DD).
     */
    fun getUsageForDate(date: String): List<Map<String, Any?>> {
        if (!hasPermission()) return emptyList()

        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val cal = Calendar.getInstance()
        cal.time = sdf.parse(date) ?: return emptyList()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val startTime = cal.timeInMillis

        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 59)
        cal.set(Calendar.SECOND, 59)
        val endTime = cal.timeInMillis

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val pm = context.packageManager
        return stats
            .filter { it.totalTimeInForeground > 0 }
            .filter { !isSystemApp(it.packageName, pm) }
            .map { stat ->
                val appName = try {
                    pm.getApplicationLabel(pm.getApplicationInfo(stat.packageName, 0)).toString()
                } catch (e: PackageManager.NameNotFoundException) {
                    stat.packageName
                }
                mapOf(
                    "package_name" to stat.packageName,
                    "app_name" to appName,
                    "usage_seconds" to (stat.totalTimeInForeground / 1000).toInt(),
                    "open_count" to (if (android.os.Build.VERSION.SDK_INT >= 29) stat.appLaunchCount else 0),
                    "category" to getCategoryForPackage(stat.packageName)
                )
            }
    }

    fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        return pm.queryIntentActivities(intent, 0).map { info ->
            val appInfo = info.activityInfo.applicationInfo
            mapOf(
                "package_name" to appInfo.packageName,
                "app_name" to pm.getApplicationLabel(appInfo).toString(),
                "category" to getCategoryForPackage(appInfo.packageName)
            )
        }
    }

    fun hasAccessibilityPermission(): Boolean {
        // Check if MindLock accessibility service is enabled
        val service = "${context.packageName}/${context.packageName}.MindLockAccessibilityService"
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains(service)
    }

    fun getForegroundApp(): String? {
        if (!hasPermission()) return null
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 60_000 // last 1 minute
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, startTime, endTime)
        return stats.maxByOrNull { it.lastTimeUsed }?.packageName
    }

    private fun isSystemApp(packageName: String, pm: PackageManager): Boolean {
        return try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
        } catch (e: PackageManager.NameNotFoundException) {
            true
        }
    }

    private fun getCategoryForPackage(packageName: String): String {
        return when {
            packageName.contains("instagram") || packageName.contains("facebook") ||
            packageName.contains("twitter") || packageName.contains("tiktok") ||
            packageName.contains("musically") || packageName.contains("snapchat") ||
            packageName.contains("reddit") || packageName.contains("linkedin") -> "social"

            packageName.contains("youtube") || packageName.contains("netflix") ||
            packageName.contains("spotify") || packageName.contains("twitch") ||
            packageName.contains("hulu") || packageName.contains("disney") -> "entertainment"

            packageName.contains("game") || packageName.contains("play") -> "games"

            packageName.contains("chrome") || packageName.contains("firefox") ||
            packageName.contains("opera") || packageName.contains("brave") -> "browser"

            packageName.contains("whatsapp") || packageName.contains("telegram") ||
            packageName.contains("signal") || packageName.contains("messenger") -> "messaging"

            else -> "other"
        }
    }
}
