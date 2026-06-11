import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_entry_model.dart';

class MoodProvider extends ChangeNotifier {
  List<MoodEntry> _entries = [];
  static const _storageKey = 'moodfood_mood_entries';

  List<MoodEntry> get entries => _entries;

  MoodEntry? get todayEntry {
    final today = DateTime.now();
    try {
      return _entries.firstWhere(
        (e) =>
            e.timestamp.year == today.year &&
            e.timestamp.month == today.month &&
            e.timestamp.day == today.day,
      );
    } catch (_) {
      return null;
    }
  }

  List<MoodEntry> get weekEntries {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  Future<void> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _entries = list
          .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    notifyListeners();
  }

  Future<void> saveMoodEntry(MoodEntry entry) async {
    _entries
      ..removeWhere(
        (e) =>
            e.timestamp.year == entry.timestamp.year &&
            e.timestamp.month == entry.timestamp.month &&
            e.timestamp.day == entry.timestamp.day,
      )
      ..insert(0, entry);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }
}
