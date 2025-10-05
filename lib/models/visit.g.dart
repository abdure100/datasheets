// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Visit _$VisitFromJson(Map<String, dynamic> json) => Visit(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      staffId: json['staffId'] as String,
      serviceCode: json['Procedure_Input'] as String,
      startTs: DateTime.parse(json['start_ts'] as String),
      endTs: json['end_ts'] == null
          ? null
          : DateTime.parse(json['end_ts'] as String),
      status: json['statusInput'] as String,
      billableMinutes: (json['billableMinutes_n'] as num?)?.toInt(),
      billableUnits: (json['units_total'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      appointmentDate: json['Appointment_date'] as String?,
      timeIn: json['time_in'] as String?,
    );

Map<String, dynamic> _$VisitToJson(Visit instance) => <String, dynamic>{
      'clientId': instance.clientId,
      'staffId': instance.staffId,
      'Procedure_Input': instance.serviceCode,
      'Appointment_date': instance.appointmentDate,
      'time_in': instance.timeIn,
    };
