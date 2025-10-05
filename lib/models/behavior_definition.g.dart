// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavior_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BehaviorDefinition _$BehaviorDefinitionFromJson(Map<String, dynamic> json) =>
    BehaviorDefinition(
      id: json['id'] as String,
      orgId: json['orgId'] as String?,
      clientId: json['clientId'] as String?,
      name: json['name'] as String,
      code: json['code'] as String,
      defaultLogType: json['defaultLogType'] as String,
      severityScaleJson: json['severityScaleJson'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$BehaviorDefinitionToJson(BehaviorDefinition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orgId': instance.orgId,
      'clientId': instance.clientId,
      'name': instance.name,
      'code': instance.code,
      'defaultLogType': instance.defaultLogType,
      'severityScaleJson': instance.severityScaleJson,
    };
