// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgramAssignment _$ProgramAssignmentFromJson(Map<String, dynamic> json) =>
    ProgramAssignment(
      id: json['PrimaryKey'] as String?,
      clientId: json['clientId'] as String?,
      ltgId: json['ltgId'] as String?,
      name: json['SubMilestone_name'] as String?,
      dataType: json['Datacollection_type'] as String?,
      status: json['Status'] as String?,
      programTemplateId: json['programTemplateId'] as String?,
      criteriaJson: json['Mastery_Criteria'] as String?,
      configJson: json['config_json'] as String?,
      phase: json['Intervention_phase'] as String?,
      masteredAt: ProgramAssignment._dateTimeFromJson(json['masteredAt_ts']),
    );

Map<String, dynamic> _$ProgramAssignmentToJson(ProgramAssignment instance) =>
    <String, dynamic>{
      'PrimaryKey': instance.id,
      'clientId': instance.clientId,
      'ltgId': instance.ltgId,
      'SubMilestone_name': instance.name,
      'Datacollection_type': instance.dataType,
      'Status': instance.status,
      'programTemplateId': instance.programTemplateId,
      'Mastery_Criteria': instance.criteriaJson,
      'config_json': instance.configJson,
      'Intervention_phase': instance.phase,
      'masteredAt_ts': instance.masteredAt?.toIso8601String(),
    };
