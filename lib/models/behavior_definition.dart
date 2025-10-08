import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'behavior_definition.g.dart';

@JsonSerializable()
class BehaviorDefinition {
  @JsonKey(name: 'PrimaryKey')
  final String id;
  
  @JsonKey(name: 'orgId')
  final String? orgId;
  
  @JsonKey(name: 'clientId')
  final String? clientId;
  
  @JsonKey(name: 'name')
  final String name;
  
  @JsonKey(name: 'code')
  final String code;
  
  @JsonKey(name: 'defaultLogType')
  final String defaultLogType;
  
  @JsonKey(name: 'severityScale_json', fromJson: _severityScaleFromJson, toJson: _severityScaleToJson)
  final Map<String, dynamic> severityScaleJson;

  const BehaviorDefinition({
    required this.id,
    this.orgId,
    this.clientId,
    required this.name,
    required this.code,
    required this.defaultLogType,
    required this.severityScaleJson,
  });

  factory BehaviorDefinition.fromJson(Map<String, dynamic> json) => _$BehaviorDefinitionFromJson(json);
  Map<String, dynamic> toJson() => _$BehaviorDefinitionToJson(this);

  Map<String, dynamic> get severityScale => 
      severityScaleJson.isNotEmpty ? Map<String, dynamic>.from(severityScaleJson) : {};

  static Map<String, dynamic> _severityScaleFromJson(dynamic json) {
    if (json == null) return {};
    if (json is Map<String, dynamic>) return json;
    if (json is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(json));
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  static dynamic _severityScaleToJson(Map<String, dynamic> severityScale) {
    return severityScale;
  }
}
