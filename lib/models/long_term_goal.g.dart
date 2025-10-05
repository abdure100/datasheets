// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'long_term_goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LongTermGoal _$LongTermGoalFromJson(Map<String, dynamic> json) => LongTermGoal(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String,
      successCriteriaJson: json['successCriteriaJson'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$LongTermGoalToJson(LongTermGoal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'title': instance.title,
      'description': instance.description,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'status': instance.status,
      'successCriteriaJson': instance.successCriteriaJson,
    };
