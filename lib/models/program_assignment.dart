import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'program_assignment.g.dart';

@JsonSerializable()
class ProgramAssignment {
  @JsonKey(name: 'PrimaryKey')
  final String? id;
  
  @JsonKey(name: 'clientId')
  final String? clientId;
  
  @JsonKey(name: 'ltgId')
  final String? ltgId;
  
  @JsonKey(name: 'SubMilestone_name')
  final String? name;
  
  @JsonKey(name: 'Datacollection_type')
  final String? dataType;
  
  @JsonKey(name: 'Status')
  final String? status;
  
  @JsonKey(name: 'programTemplateId')
  final String? programTemplateId;
  
  @JsonKey(name: 'Mastery_Criteria')
  final String? criteriaJson;
  
  @JsonKey(name: 'config_json')
  final String? configJson;
  
  @JsonKey(name: 'Intervention_phase')
  final String? phase;
  
  @JsonKey(name: 'masteredAt_ts', fromJson: _dateTimeFromJson)
  final DateTime? masteredAt;

  const ProgramAssignment({
    this.id,
    this.clientId,
    this.ltgId,
    this.name,
    this.dataType,
    this.status,
    this.programTemplateId,
    this.criteriaJson,
    this.configJson,
    this.phase,
    this.masteredAt,
  });

  factory ProgramAssignment.fromJson(Map<String, dynamic> json) => _$ProgramAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$ProgramAssignmentToJson(this);

  Map<String, dynamic> get criteria {
    try {
      return (criteriaJson?.isNotEmpty == true) ? Map<String, dynamic>.from(jsonDecode(criteriaJson!)) : {};
    } catch (e) {
      return {};
    }
  }

  Map<String, dynamic> get config {
    try {
      return (configJson?.isNotEmpty == true) ? Map<String, dynamic>.from(jsonDecode(configJson!)) : {};
    } catch (e) {
      return {};
    }
  }

  bool get isActive => status?.toLowerCase() == 'active';
  bool get isMastered => status?.toLowerCase() == 'mastered';
  
  // Safe getters for display
  String get displayName => name ?? 'Unnamed Program';
  String get displayDataType => dataType ?? 'Unknown';
  String get displayStatus => status ?? 'Unknown';
  String get displayPhase => phase ?? 'Unknown';
  
  // Helper function for DateTime parsing
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
}
