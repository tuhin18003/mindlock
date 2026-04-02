import 'monitored_app_model.dart';

class AppDeviceConfig {
  final List<MonitoredAppModel> monitoredApps;
  final Map<String, int> todayUsageSeconds; // packageName → seconds
  final bool isPro;

  const AppDeviceConfig({
    required this.monitoredApps,
    required this.todayUsageSeconds,
    required this.isPro,
  });

  factory AppDeviceConfig.fromJson(Map<String, dynamic> json) {
    final appsJson = json['monitored_apps'] as List<dynamic>? ?? [];
    final usageJson = json['today_usage_seconds'] as Map<String, dynamic>? ?? {};

    return AppDeviceConfig(
      monitoredApps: appsJson
          .map((e) => MonitoredAppModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      todayUsageSeconds: usageJson.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      isPro: json['is_pro'] as bool? ?? false,
    );
  }

  factory AppDeviceConfig.empty() {
    return const AppDeviceConfig(
      monitoredApps: [],
      todayUsageSeconds: {},
      isPro: false,
    );
  }
}
