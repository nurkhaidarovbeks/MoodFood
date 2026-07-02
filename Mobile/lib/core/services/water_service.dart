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
}
