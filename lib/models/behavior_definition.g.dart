// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavior_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BehaviorDefinition _$BehaviorDefinitionFromJson(Map<String, dynamic> json) =>
    BehaviorDefinition(
      id: json['PrimaryKey'] as String,
      orgId: json['orgId'] as String?,
      clientId: json['clientId'] as String?,
      name: json['behavior_name'] as String,
      code: json['behavior_code'] as String,
      defaultLogType: json['data_collection_method'] as String,
      severityScaleJson:
          BehaviorDefinition._severityScaleFromJson(json['severityScale_json']),
    );

Map<String, dynamic> _$BehaviorDefinitionToJson(BehaviorDefinition instance) =>
    <String, dynamic>{
      'PrimaryKey': instance.id,
      'orgId': instance.orgId,
      'clientId': instance.clientId,
      'behavior_name': instance.name,
      'behavior_code': instance.code,
      'data_collection_method': instance.defaultLogType,
      'severityScale_json':
          BehaviorDefinition._severityScaleToJson(instance.severityScaleJson),
    };
