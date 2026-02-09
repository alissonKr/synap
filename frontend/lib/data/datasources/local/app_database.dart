import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'synap.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}

class Conversations extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();

  TextColumn get conversationId => text()();

  TextColumn get role => text()();

  TextColumn get content => text()();

  IntColumn get createdAt => integer()();

  BoolColumn get hasImage => boolean().withDefault(const Constant(false))();

  TextColumn get imagePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Index> get indexes => [Index('messages_conversation_idx', [conversationId])];
}

class DailyUsage extends Table {
  TextColumn get day => text()();

  IntColumn get textCount => integer().withDefault(const Constant(0))();

  IntColumn get imageCount => integer().withDefault(const Constant(0))();

  IntColumn get lastUpdatedAt => integer()();

  @override
  Set<Column> get primaryKey => {day};
}

@DriftDatabase(tables: [Conversations, Messages, DailyUsage])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}
