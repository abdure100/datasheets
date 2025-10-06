import 'package:json_annotation/json_annotation.dart';

part 'behavior_log.g.dart';

@JsonSerializable()
class BehaviorLog {
  @JsonKey(name: 'PrimaryKey')
  final String id;
  
  @JsonKey(name: 'visitId')
  final String visitId;
  
  @JsonKey(name: 'clientId')
  final String clientId;
  
  @JsonKey(name: 'behaviorId')
  final String behaviorId;
  
  @JsonKey(name: 'assignmentId')
  final String? assignmentId;
  
  @JsonKey(name: 'startTs_ts', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? startTs;
  
  @JsonKey(name: 'endTs_ts', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? endTs;
  
  @JsonKey(name: 'durationSec')
  final int? durationSec;
  
  @JsonKey(name: 'count')
  final int? count;
  
  @JsonKey(name: 'ratePerMin')
  final double? ratePerMin;
  
  @JsonKey(name: 'antecedent')
  final String? antecedent;
  
  @JsonKey(name: 'behaviorDesc')
  final String? behaviorDesc;
  
  @JsonKey(name: 'consequence')
  final String? consequence;
  
  @JsonKey(name: 'setting')
  final String? setting;
  
  @JsonKey(name: 'perceivedFunction')
  final String? perceivedFunction;
  
  @JsonKey(name: 'severity')
  final int? severity;
  
  @JsonKey(name: 'injury', fromJson: _boolFromJson, toJson: _boolToJson)
  final bool? injury;
  
  @JsonKey(name: 'restraintUsed', fromJson: _boolFromJson, toJson: _boolToJson)
  final bool? restraintUsed;
  
  @JsonKey(name: 'notes')
  final String? notes;
  
  @JsonKey(name: 'collector')
  final String? collector;
  
  @JsonKey(name: 'createdAt_ts', fromJson: _dateTimeFromJsonNonNull, toJson: _dateTimeToJson)
  final DateTime createdAt;
  
  @JsonKey(name: 'updatedAt_ts', fromJson: _dateTimeFromJsonNonNull, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  const BehaviorLog({
    required this.id,
    required this.visitId,
    required this.clientId,
    required this.behaviorId,
    this.assignmentId,
    this.startTs,
    this.endTs,
    this.durationSec,
    this.count,
    this.ratePerMin,
    this.antecedent,
    this.behaviorDesc,
    this.consequence,
    this.setting,
    this.perceivedFunction,
    this.severity,
    this.injury,
    this.restraintUsed,
    this.notes,
    this.collector,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BehaviorLog.fromJson(Map<String, dynamic> json) => _$BehaviorLogFromJson(json);
  Map<String, dynamic> toJson() => _$BehaviorLogToJson(this);

  BehaviorLog copyWith({
    String? id,
    String? visitId,
    String? clientId,
    String? behaviorId,
    String? assignmentId,
    DateTime? startTs,
    DateTime? endTs,
    int? durationSec,
    int? count,
    double? ratePerMin,
    String? antecedent,
    String? behaviorDesc,
    String? consequence,
    String? setting,
    String? perceivedFunction,
    int? severity,
    bool? injury,
    bool? restraintUsed,
    String? notes,
    String? collector,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BehaviorLog(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      clientId: clientId ?? this.clientId,
      behaviorId: behaviorId ?? this.behaviorId,
      assignmentId: assignmentId ?? this.assignmentId,
      startTs: startTs ?? this.startTs,
      endTs: endTs ?? this.endTs,
      durationSec: durationSec ?? this.durationSec,
      count: count ?? this.count,
      ratePerMin: ratePerMin ?? this.ratePerMin,
      antecedent: antecedent ?? this.antecedent,
      behaviorDesc: behaviorDesc ?? this.behaviorDesc,
      consequence: consequence ?? this.consequence,
      setting: setting ?? this.setting,
      perceivedFunction: perceivedFunction ?? this.perceivedFunction,
      severity: severity ?? this.severity,
      injury: injury ?? this.injury,
      restraintUsed: restraintUsed ?? this.restraintUsed,
      notes: notes ?? this.notes,
      collector: collector ?? this.collector,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isTiming => startTs != null && endTs != null;
  bool get isCounting => count != null;
  bool get isABC => antecedent != null || behaviorDesc != null || consequence != null;

  // Helper functions for DateTime conversion
  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static DateTime _dateTimeFromJsonNonNull(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String().split('.')[0] ?? '';
  }

  // Helper functions for boolean conversion to/from strings for FileMaker compatibility
  static bool? _boolFromJson(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }

  static String? _boolToJson(bool? value) {
    if (value == null) return null;
    return value ? 'true' : 'false';
  }
}
