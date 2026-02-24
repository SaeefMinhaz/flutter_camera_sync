import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Drift table for capture batches.
@DataClassName('Batch')
class Batches extends Table {
  TextColumn get id => text()();

  DateTimeColumn get createdAt => dateTime()();

  TextColumn get label => text().nullable()();

  // pending, uploading, uploaded, failed
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for individual captured images.
class Images extends Table {
  TextColumn get id => text()();

  TextColumn get filePath => text()();

  DateTimeColumn get capturedAt => dateTime()();

  TextColumn get batchId => text().nullable().references(Batches, #id)();

  TextColumn get thumbnailPath => text().nullable()();

  IntColumn get width => integer().nullable()();

  IntColumn get height => integer().nullable()();

  TextColumn get deviceName => text().nullable()();

  // pending, uploading, uploaded, failed
  TextColumn get uploadStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(dir.path, 'camera_sync.sqlite');
    return NativeDatabase(File(dbPath));
  });
}

/// Central application database.
///
/// At this stage we keep the schema small and let later features
/// extend it when needed.
@DriftDatabase(tables: [Batches, Images])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

