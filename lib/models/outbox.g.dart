// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Outbox _$OutboxFromJson(Map<String, dynamic> json) => Outbox(
      id: (json['id'] as num?)?.toInt(),
      entityType: json['entityType'] as String,
      operation: json['operation'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
    );

Map<String, dynamic> _$OutboxToJson(Outbox instance) => <String, dynamic>{
      'id': instance.id,
      'entityType': instance.entityType,
      'operation': instance.operation,
      'payload': instance.payload,
      'syncStatus': instance.syncStatus,
      'retryCount': instance.retryCount,
      'errorMessage': instance.errorMessage,
      'createdAt': instance.createdAt.toIso8601String(),
      'syncedAt': instance.syncedAt?.toIso8601String(),
    };
