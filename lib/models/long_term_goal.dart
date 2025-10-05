import 'package:json_annotation/json_annotation.dart';

part 'long_term_goal.g.dart';

@JsonSerializable()
class LongTermGoal {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final Map<String, dynamic> successCriteriaJson;

  const LongTermGoal({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.successCriteriaJson,
  });

  factory LongTermGoal.fromJson(Map<String, dynamic> json) => _$LongTermGoalFromJson(json);
  Map<String, dynamic> toJson() => _$LongTermGoalToJson(this);
}
