import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/outbox.dart';

/// Local SQLite database helper for offline-first operations
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static Database? _database;

  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'datasheets.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create Outboxes table
        await db.execute('''
          CREATE TABLE outboxes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            operation TEXT NOT NULL,
            payload TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            retry_count INTEGER NOT NULL DEFAULT 0,
            error_message TEXT,
            created_at TEXT NOT NULL,
            synced_at TEXT
          )
        ''');

        // Create indexes for better query performance
        await db.execute('''
          CREATE INDEX idx_outboxes_sync_status ON outboxes(sync_status)
        ''');
        await db.execute('''
          CREATE INDEX idx_outboxes_entity_type ON outboxes(entity_type)
        ''');
        await db.execute('''
          CREATE INDEX idx_outboxes_created_at ON outboxes(created_at)
        ''');
      },
    );
  }

  /// Add an operation to the outbox queue
  Future<int> addToOutbox(Outbox outbox) async {
    final db = await database;
    return await db.insert(
      'outboxes',
      {
        'entity_type': outbox.entityType,
        'operation': outbox.operation,
        'payload': jsonEncode(outbox.payload),
        'sync_status': outbox.syncStatus,
        'retry_count': outbox.retryCount,
        'error_message': outbox.errorMessage,
        'created_at': outbox.createdAt.toIso8601String(),
        'synced_at': outbox.syncedAt?.toIso8601String(),
      },
    );
  }

  /// Get all pending outbox items
  Future<List<Outbox>> getPendingOutboxes({int? limit}) async {
    final db = await database;
    final results = await db.query(
      'outboxes',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return results.map((row) => _outboxFromRow(row)).toList();
  }

  /// Get all failed outbox items that can be retried
  Future<List<Outbox>> getRetryableOutboxes({int? limit}) async {
    final db = await database;
    final results = await db.query(
      'outboxes',
      where: 'sync_status = ? AND retry_count < ?',
      whereArgs: ['failed', 5],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return results.map((row) => _outboxFromRow(row)).toList();
  }

  /// Get all outbox items (for sync banner count)
  Future<List<Outbox>> getAllOutboxes({String? syncStatus}) async {
    final db = await database;
    final results = await db.query(
      'outboxes',
      where: syncStatus != null ? 'sync_status = ?' : null,
      whereArgs: syncStatus != null ? [syncStatus] : null,
      orderBy: 'created_at DESC',
    );

    return results.map((row) => _outboxFromRow(row)).toList();
  }

  /// Get count of pending items
  Future<int> getPendingCount() async {
    final db = await database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM outboxes WHERE sync_status = ?',
        ['pending'],
      ),
    );
    return result ?? 0;
  }

  /// Update outbox item
  Future<int> updateOutbox(Outbox outbox) async {
    if (outbox.id == null) {
      throw Exception('Cannot update outbox without id');
    }

    final db = await database;
    return await db.update(
      'outboxes',
      {
        'entity_type': outbox.entityType,
        'operation': outbox.operation,
        'payload': jsonEncode(outbox.payload),
        'sync_status': outbox.syncStatus,
        'retry_count': outbox.retryCount,
        'error_message': outbox.errorMessage,
        'created_at': outbox.createdAt.toIso8601String(),
        'synced_at': outbox.syncedAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [outbox.id],
    );
  }

  /// Delete outbox item (after successful sync)
  Future<int> deleteOutbox(int id) async {
    final db = await database;
    return await db.delete(
      'outboxes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark outbox as syncing
  Future<int> markAsSyncing(int id) async {
    final db = await database;
    return await db.update(
      'outboxes',
      {'sync_status': 'syncing'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark outbox as synced
  Future<int> markAsSynced(int id) async {
    final db = await database;
    return await db.update(
      'outboxes',
      {
        'sync_status': 'synced',
        'synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark outbox as failed
  Future<int> markAsFailed(int id, String errorMessage, int retryCount) async {
    final db = await database;
    return await db.update(
      'outboxes',
      {
        'sync_status': 'failed',
        'error_message': errorMessage,
        'retry_count': retryCount,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Convert database row to Outbox model
  Outbox _outboxFromRow(Map<String, dynamic> row) {
    return Outbox(
      id: row['id'] as int?,
      entityType: row['entity_type'] as String,
      operation: row['operation'] as String,
      payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      syncStatus: row['sync_status'] as String,
      retryCount: row['retry_count'] as int,
      errorMessage: row['error_message'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      syncedAt: row['synced_at'] != null
          ? DateTime.parse(row['synced_at'] as String)
          : null,
    );
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

