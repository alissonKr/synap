import 'package:drift/drift.dart';

import 'app_database.dart';

class DailyUsageService {
  DailyUsageService(this._db);

  final AppDatabase _db;

  Future<bool> canSendText({int freeDailyTextLimit = 30}) async {
    final usage = await _getTodayUsage();

    return usage.textCount < freeDailyTextLimit;
  }

  Future<bool> canSendImage({int freeDailyImageLimit = 3}) async {
    final usage = await _getTodayUsage();

    return usage.imageCount < freeDailyImageLimit;
  }

  Future<void> incrementText() async {
    final usage = await _getTodayUsage();
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.dailyUsage)..where((tbl) => tbl.day.equals(usage.day))).write(
      DailyUsageCompanion(
        textCount: Value(usage.textCount + 1),
        lastUpdatedAt: Value(now),
      ),
    );
  }

  Future<void> incrementImage() async {
    final usage = await _getTodayUsage();
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.dailyUsage)..where((tbl) => tbl.day.equals(usage.day))).write(
      DailyUsageCompanion(
        imageCount: Value(usage.imageCount + 1),
        lastUpdatedAt: Value(now),
      ),
    );
  }

  Future<DailyUsageData> _getTodayUsage() async {
    final today = _todayString();

    final existingQuery = _db.select(_db.dailyUsage)..where((tbl) => tbl.day.equals(today));
    final existing = await existingQuery.getSingleOrNull();

    if (existing != null) {
      return existing;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = DailyUsageCompanion(
      day: Value(today),
      textCount: const Value(0),
      imageCount: const Value(0),
      lastUpdatedAt: Value(now),
    );

    await _db.into(_db.dailyUsage).insertOnConflictUpdate(companion);

    return DailyUsageData(
      day: today,
      textCount: 0,
      imageCount: 0,
      lastUpdatedAt: now,
    );
  }

  String _todayString() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }
}
