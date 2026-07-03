import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';

class WaterLog {
  final String id;
  final int amountMl;
  final DateTime createdAt;

  const WaterLog({required this.id, required this.amountMl, required this.createdAt});

  factory WaterLog.fromJson(Map<String, dynamic> j) => WaterLog(
        id: j['id'] as String,
        amountMl: (j['amountMl'] as num).toInt(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Today's hydration summary — mirrors GET /water/today.
class WaterToday {
  final int goalMl;
  final int totalMl;
  final int remainingMl;
  final double progress; // 0..1
  final bool goalReached;
  final List<WaterLog> logs;

  const WaterToday({
    required this.goalMl,
    required this.totalMl,
    required this.remainingMl,
    required this.progress,
    required this.goalReached,
    required this.logs,
  });

  factory WaterToday.fromJson(Map<String, dynamic> j) => WaterToday(
        goalMl: (j['goalMl'] as num?)?.toInt() ?? 2000,
        totalMl: (j['totalMl'] as num?)?.toInt() ?? 0,
        remainingMl: (j['remainingMl'] as num?)?.toInt() ?? 0,
        progress: (j['progress'] as num?)?.toDouble() ?? 0,
        goalReached: j['goalReached'] as bool? ?? false,
        logs: (j['logs'] as List<dynamic>?)
                ?.map((e) => WaterLog.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );

  static const empty = WaterToday(
    goalMl: 2000,
    totalMl: 0,
    remainingMl: 2000,
    progress: 0,
    goalReached: false,
    logs: [],
  );
}

/// One day in the weekly history — mirrors an item from GET /water/history.
class WaterDay {
  final String date; // yyyy-MM-dd (local)
  final int totalMl;
  final bool goalReached;

  const WaterDay({
    required this.date,
    required this.totalMl,
    required this.goalReached,
  });

  factory WaterDay.fromJson(Map<String, dynamic> j) => WaterDay(
        date: j['date'] as String? ?? '',
        totalMl: (j['totalMl'] as num?)?.toInt() ?? 0,
        goalReached: j['goalReached'] as bool? ?? false,
      );
}

class WaterHistory {
  final int goalMl;
  final List<WaterDay> days; // oldest → newest

  const WaterHistory({required this.goalMl, required this.days});

  factory WaterHistory.fromJson(Map<String, dynamic> j) => WaterHistory(
        goalMl: (j['goalMl'] as num?)?.toInt() ?? 2000,
        days: (j['days'] as List<dynamic>?)
                ?.map((e) => WaterDay.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );

  static const empty = WaterHistory(goalMl: 2000, days: []);
}

/// Hydration goal + reminder settings — mirrors GET/PUT /water/goal.
class WaterGoal {
  final int waterGoalMl;
  final bool waterRemindersOn;
  final int waterIntervalMin;
  final String wakeTime; // HH:mm
  final String sleepTime; // HH:mm

  const WaterGoal({
    required this.waterGoalMl,
    required this.waterRemindersOn,
    required this.waterIntervalMin,
    required this.wakeTime,
    required this.sleepTime,
  });

  factory WaterGoal.fromJson(Map<String, dynamic> j) => WaterGoal(
        waterGoalMl: (j['waterGoalMl'] as num?)?.toInt() ?? 2000,
        waterRemindersOn: j['waterRemindersOn'] as bool? ?? true,
        waterIntervalMin: (j['waterIntervalMin'] as num?)?.toInt() ?? 120,
        wakeTime: j['wakeTime'] as String? ?? '08:00',
        sleepTime: j['sleepTime'] as String? ?? '23:00',
      );

  static const defaults = WaterGoal(
    waterGoalMl: 2000,
    waterRemindersOn: true,
    waterIntervalMin: 120,
    wakeTime: '08:00',
    sleepTime: '23:00',
  );
}

class WaterService {
  final _api = ApiClient.instance;

  /// GET /water/today. Returns null on error so the provider can keep cache.
  Future<WaterToday?> today() async {
    try {
      final res = await _api.dio.get(ApiConstants.waterToday);
      return WaterToday.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (_) {
      return null;
    }
  }

  /// POST /water { amountMl } — logs a drink, returns the refreshed today summary.
  Future<WaterToday?> log(int amountMl) async {
    try {
      final res = await _api.dio.post(
        ApiConstants.water,
        data: {'amountMl': amountMl},
      );
      return WaterToday.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException {
      return null;
    }
  }

  /// DELETE /water/:id — removes a log, returns the refreshed today summary.
  Future<WaterToday?> deleteLog(String id) async {
    try {
      final res = await _api.dio.delete('${ApiConstants.water}/$id');
      return WaterToday.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException {
      return null;
    }
  }

  /// GET /water/history?days=N — per-day totals for the last N days.
  Future<WaterHistory?> history({int days = 7}) async {
    try {
      final res = await _api.dio.get(
        ApiConstants.waterHistory,
        queryParameters: {'days': days},
      );
      return WaterHistory.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (_) {
      return null;
    }
  }

  /// GET /water/goal — hydration goal + reminder settings.
  Future<WaterGoal?> getGoal() async {
    try {
      final res = await _api.dio.get(ApiConstants.waterGoal);
      return WaterGoal.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (_) {
      return null;
    }
  }

  /// PUT /water/goal — update goal and/or reminder cadence. Returns updated goal.
  Future<WaterGoal?> updateGoal({
    int? waterGoalMl,
    bool? waterRemindersOn,
    int? waterIntervalMin,
    String? wakeTime,
    String? sleepTime,
  }) async {
    try {
      final res = await _api.dio.put(
        ApiConstants.waterGoal,
        data: {
          if (waterGoalMl != null) 'waterGoalMl': waterGoalMl,
          if (waterRemindersOn != null) 'waterRemindersOn': waterRemindersOn,
          if (waterIntervalMin != null) 'waterIntervalMin': waterIntervalMin,
          if (wakeTime != null) 'wakeTime': wakeTime,
          if (sleepTime != null) 'sleepTime': sleepTime,
        },
      );
      return WaterGoal.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException {
      return null;
    }
  }
}
