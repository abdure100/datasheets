import 'package:json_annotation/json_annotation.dart';

part 'outbox.g.dart';

/// Represents a pending operation in the outbox queue
/// This follows the Outbox Pattern for offline-first architecture
@JsonSerializable()
class Outbox {
  final int? id;
  final String entityType; // e.g., 'visit', 'session_record', 'behavior_log'
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic> payload; // JSON data for the operation
  final String syncStatus; // 'pending', 'syncing', 'synced', 'failed'
  final int retryCount; // Number of sync attempts (max 5)
  final String? errorMessage; // Last error message if sync failed
  final DateTime createdAt;
  final DateTime? syncedAt;

  Outbox({
    this.id,
    required this.entityType,
    required this.operation,
    required this.payload,
    this.syncStatus = 'pending',
    this.retryCount = 0,
    this.errorMessage,
    DateTime? createdAt,
    this.syncedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Outbox.fromJson(Map<String, dynamic> json) => _$OutboxFromJson(json);
  Map<String, dynamic> toJson() => _$OutboxToJson(this);

  Outbox copyWith({
    int? id,
    String? entityType,
    String? operation,
    Map<String, dynamic>? payload,
    String? syncStatus,
    int? retryCount,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) {
    return Outbox(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  bool get canRetry => retryCount < 5 && syncStatus == 'failed';
  bool get isPending => syncStatus == 'pending';
  bool get isSyncing => syncStatus == 'syncing';
  bool get isSynced => syncStatus == 'synced';
  bool get isFailed => syncStatus == 'failed';
}

