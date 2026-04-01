package com.mindlock.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val USAGE_CHANNEL = "com.mindlock.app/usage_stats"
    private lateinit var usageStatsHandler: UsageStatsHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        usageStatsHandler = UsageStatsHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsageForDate" -> {
                    val date = call.argument<String>("date")
                    if (date == null) {
                        result.error("INVALID_ARG", "date is required", null)
                        return@setMethodCallHandler
                    }
                    val usage = usageStatsHandler.getUsageForDate(date)
                    result.success(usage)
                }

                "hasUsageStatsPermission" -> {
                    result.success(usageStatsHandler.hasPermission())
                }

                "openUsageStatsSettings" -> {
                    usageStatsHandler.openSettings()
                    result.success(null)
                }

                "getInstalledApps" -> {
                    val apps = usageStatsHandler.getInstalledApps()
                    result.success(apps)
                }

                "hasAccessibilityPermission" -> {
                    result.success(usageStatsHandler.hasAccessibilityPermission())
                }

                "getForegroundApp" -> {
                    result.success(usageStatsHandler.getForegroundApp())
                }

                else -> result.notImplemented()
            }
        }
    }
}
