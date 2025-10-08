// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavior_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BehaviorLog _$BehaviorLogFromJson(Map<String, dynamic> json) => BehaviorLog(
      id: json['PrimaryKey'] as String,
      visitId: json['visitId'] as String,
      clientId: json['clientId'] as String,
      behaviorId: json['behaviorId'] as String,
      assignmentId: json['assignmentId'] as String?,
      startTs: BehaviorLog._dateTimeFromJson(json['startTs_ts']),
      endTs: BehaviorLog._dateTimeFromJson(json['endTs_ts']),
      durationSec: (json['durationSec'] as num?)?.toInt(),
      count: (json['count'] as num?)?.toInt(),
      ratePerMin: (json['ratePerMin'] as num?)?.toDouble(),
      antecedent: json['antecedent'] as String?,
      behaviorDesc: json['behaviorDesc'] as String?,
      consequence: json['consequence'] as String?,
      setting: json['setting'] as String?,
      perceivedFunction: json['perceivedFunction'] as String?,
      severity: (json['severity'] as num?)?.toInt(),
      injury: BehaviorLog._boolFromJson(json['injury']),
      restraintUsed: BehaviorLog._boolFromJson(json['restraintUsed']),
      notes: json['notes'] as String?,
      collector: json['collector'] as String?,
      createdAt: BehaviorLog._dateTimeFromJsonNonNull(json['createdAt_ts']),
      updatedAt: BehaviorLog._dateTimeFromJsonNonNull(json['updatedAt_ts']),
      behaviorName: json['behavior_name'] as String?,
    );

Map<String, dynamic> _$BehaviorLogToJson(BehaviorLog instance) =>
    <String, dynamic>{
      'PrimaryKey': instance.id,
      'visitId': instance.visitId,
      'clientId': instance.clientId,
      'behaviorId': instance.behaviorId,
      'assignmentId': instance.assignmentId,
      'startTs_ts': BehaviorLog._dateTimeToJson(instance.startTs),
      'endTs_ts': BehaviorLog._dateTimeToJson(instance.endTs),
      'durationSec': instance.durationSec,
      'count': instance.count,
      'ratePerMin': instance.ratePerMin,
      'antecedent': instance.antecedent,
      'behaviorDesc': instance.behaviorDesc,
      'consequence': instance.consequence,
      'setting': instance.setting,
      'perceivedFunction': instance.perceivedFunction,
      'severity': instance.severity,
      'injury': BehaviorLog._boolToJson(instance.injury),
      'restraintUsed': BehaviorLog._boolToJson(instance.restraintUsed),
      'notes': instance.notes,
      'collector': instance.collector,
      'createdAt_ts': BehaviorLog._dateTimeToJson(instance.createdAt),
      'updatedAt_ts': BehaviorLog._dateTimeToJson(instance.updatedAt),
    };
