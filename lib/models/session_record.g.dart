// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionRecord _$SessionRecordFromJson(Map<String, dynamic> json) =>
    SessionRecord(
      id: json['PrimaryKey'] as String,
      visitId: json['visitId'] as String,
      clientId: json['clientId'] as String,
      assignmentId: json['assignmentId'] as String,
      startedAt: SessionRecord._dateTimeFromJson(json['startedAt_ts']),
      updatedAt: SessionRecord._dateTimeFromJson(json['updatedAt_ts']),
      payload: json['payload_json'] as Map<String, dynamic>,
      notes: json['notes'] as String?,
      staffId: json['staffId'] as String?,
      interventionPhase: json['intervention_phase'] as String?,
    );

Map<String, dynamic> _$SessionRecordToJson(SessionRecord instance) =>
    <String, dynamic>{
      'PrimaryKey': instance.id,
      'visitId': instance.visitId,
      'clientId': instance.clientId,
      'assignmentId': instance.assignmentId,
      'startedAt_ts': SessionRecord._dateTimeToJson(instance.startedAt),
      'updatedAt_ts': SessionRecord._dateTimeToJson(instance.updatedAt),
      'payload_json': instance.payload,
      'notes': instance.notes,
      'staffId': instance.staffId,
      'intervention_phase': instance.interventionPhase,
    };
