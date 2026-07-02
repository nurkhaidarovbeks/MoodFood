import '../api/api_client.dart';
import '../constants/api_constants.dart';

class HydrationSummary {
  final int goalMl;
  final int avgDailyMl;
  final int goalReachedDays;
  final double adherence; // 0..1

  const HydrationSummary({
    required this.goalMl,
    required this.avgDailyMl,
    required this.goalReachedDays,
    required this.adherence,
  });

  factory HydrationSummary.fromJson(Map<String, dynamic> j) => HydrationSummary(
        goalMl: (j['goalMl'] as num?)?.toInt() ?? 2000,
        avgDailyMl: (j['avgDailyMl'] as num?)?.toInt() ?? 0,
        goalReachedDays: (j['goalReachedDays'] as num?)?.toInt() ?? 0,
        adherence: (j['adherence'] as num?)?.toDouble() ?? 0,
      );
}

/// Epic 7 — weekly habit analytics from GET /insights/weekly.
class WeeklyInsights {
  final int periodDays;
  final int moodCheckIns;
  final int daysWithCheckIn;
  final double checkInRate; // 0..1
  final double? avgEnergy;
  final String? dominantMood;
  final Map<String, int> moodCounts;
  final int poorSleepDays;
  final HydrationSummary hydration;
  final List<String> tips;

  const WeeklyInsights({
    required this.periodDays,
    required this.moodCheckIns,
    required this.daysWithCheckIn,
    required this.checkInRate,
    required this.avgEnergy,
    required this.dominantMood,
    required this.moodCounts,
    required this.poorSleepDays,
    required this.hydration,
    required this.tips,
  });

  factory WeeklyInsights.fromJson(Map<String, dynamic> j) => WeeklyInsights(
        periodDays: (j['periodDays'] as num?)?.toInt() ?? 7,
        moodCheckIns: (j['moodCheckIns'] as num?)?.toInt() ?? 0,
        daysWithCheckIn: (j['daysWithCheckIn'] as num?)?.toInt() ?? 0,
        checkInRate: (j['checkInRate'] as num?)?.toDouble() ?? 0,
        avgEnergy: (j['avgEnergy'] as num?)?.toDouble(),
        dominantMood: j['dominantMood'] as String?,
        moodCounts: (j['moodCounts'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toInt()),
            ) ??
            {},
        poorSleepDays: (j['poorSleepDays'] as num?)?.toInt() ?? 0,
        hydration: HydrationSummary.fromJson(
            Map<String, dynamic>.from(j['hydration'] as Map? ?? {})),
        tips: (j['tips'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class InsightsService {
  final _api = ApiClient.instance;

  Future<WeeklyInsights?> weekly({int days = 7}) async {
    try {
      final res = await _api.dio.get(
        ApiConstants.insightsWeekly,
        queryParameters: {'days': days},
      );
      return WeeklyInsights.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> tips({int days = 7}) async {
    try {
      final res = await _api.dio.get(
        ApiConstants.insightsTips,
        queryParameters: {'days': days},
      );
      final data = res.data;
      final list = data is Map ? (data['tips'] as List<dynamic>? ?? []) : [];
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
