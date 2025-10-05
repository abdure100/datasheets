// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavior_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BehaviorLog _$BehaviorLogFromJson(Map<String, dynamic> json) => BehaviorLog(
      id: json['id'] as String,
      visitId: json['visitId'] as String,
      clientId: json['clientId'] as String,
      behaviorId: json['behaviorId'] as String,
      assignmentId: json['assignmentId'] as String?,
      startTs: json['startTs'] == null
          ? null
          : DateTime.parse(json['startTs'] as String),
      endTs: json['endTs'] == null
          ? null
          : DateTime.parse(json['endTs'] as String),
      durationSec: (json['durationSec'] as num?)?.toInt(),
      count: (json['count'] as num?)?.toInt(),
      ratePerMin: (json['ratePerMin'] as num?)?.toDouble(),
      antecedent: json['antecedent'] as String?,
      behaviorDesc: json['behaviorDesc'] as String?,
      consequence: json['consequence'] as String?,
      setting: json['setting'] as String?,
      perceivedFunction: json['perceivedFunction'] as String?,
      severity: (json['severity'] as num?)?.toInt(),
      injury: json['injury'] as bool?,
      restraintUsed: json['restraintUsed'] as bool?,
      notes: json['notes'] as String?,
      collector: json['collector'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BehaviorLogToJson(BehaviorLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visitId': instance.visitId,
      'clientId': instance.clientId,
      'behaviorId': instance.behaviorId,
      'assignmentId': instance.assignmentId,
      'startTs': instance.startTs?.toIso8601String(),
      'endTs': instance.endTs?.toIso8601String(),
      'durationSec': instance.durationSec,
      'count': instance.count,
      'ratePerMin': instance.ratePerMin,
      'antecedent': instance.antecedent,
      'behaviorDesc': instance.behaviorDesc,
      'consequence': instance.consequence,
      'setting': instance.setting,
      'perceivedFunction': instance.perceivedFunction,
      'severity': instance.severity,
      'injury': instance.injury,
      'restraintUsed': instance.restraintUsed,
      'notes': instance.notes,
      'collector': instance.collector,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
