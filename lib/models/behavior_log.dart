import 'package:json_annotation/json_annotation.dart';

part 'behavior_log.g.dart';

@JsonSerializable()
class BehaviorLog {
  final String id;
  final String visitId;
  final String clientId;
  final String behaviorId;
  final String? assignmentId;
  final DateTime? startTs;
  final DateTime? endTs;
  final int? durationSec;
  final int? count;
  final double? ratePerMin;
  final String? antecedent;
  final String? behaviorDesc;
  final String? consequence;
  final String? setting;
  final String? perceivedFunction;
  final int? severity;
  final bool? injury;
  final bool? restraintUsed;
  final String? notes;
  final String? collector;
  final DateTime createdAt;
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
}
