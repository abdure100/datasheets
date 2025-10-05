import 'package:json_annotation/json_annotation.dart';

part 'behavior_definition.g.dart';

@JsonSerializable()
class BehaviorDefinition {
  final String id;
  final String? orgId;
  final String? clientId;
  final String name;
  final String code;
  final String defaultLogType;
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
}
