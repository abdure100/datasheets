import 'package:json_annotation/json_annotation.dart';

part 'visit.g.dart';

String? _dateTimeToFileMakerString(DateTime? dateTime) {
  if (dateTime == null) return null;
  final formatted = '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  print('Formatting DateTime: $dateTime -> $formatted');
  return formatted;
}

@JsonSerializable()
class Visit {
  @JsonKey(includeFromJson: true, includeToJson: false)
  final String id;
  @JsonKey(name: 'clientId')
  final String clientId;
  @JsonKey(name: 'staffId')
  final String staffId;
  @JsonKey(name: 'Procedure_Input')
  final String serviceCode;
  @JsonKey(name: 'start_ts', toJson: _dateTimeToFileMakerString, includeToJson: false)
  final DateTime startTs;
  @JsonKey(name: 'end_ts', toJson: _dateTimeToFileMakerString, includeToJson: false)
  final DateTime? endTs;
  @JsonKey(name: 'statusInput', includeToJson: false)
  final String status;
  @JsonKey(name: 'billableMinutes_n', includeToJson: false)
  final int? billableMinutes;
  @JsonKey(name: 'units_total', includeToJson: false)
  final int? billableUnits;
  @JsonKey(name: 'notes', includeToJson: false)
  final String? notes;
  @JsonKey(name: 'Appointment_date')
  final String? appointmentDate;
  @JsonKey(name: 'time_in')
  final String? timeIn;

  const Visit({
    required this.id,
    required this.clientId,
    required this.staffId,
    required this.serviceCode,
    required this.startTs,
    this.endTs,
    required this.status,
    this.billableMinutes,
    this.billableUnits,
    this.notes,
    this.appointmentDate,
    this.timeIn,
  });

  factory Visit.fromJson(Map<String, dynamic> json) => _$VisitFromJson(json);
  Map<String, dynamic> toJson() => _$VisitToJson(this);

  Visit copyWith({
    String? id,
    String? clientId,
    String? staffId,
    String? serviceCode,
    DateTime? startTs,
    DateTime? endTs,
    String? status,
    int? billableMinutes,
    int? billableUnits,
    String? notes,
    String? appointmentDate,
    String? timeIn,
  }) {
    return Visit(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      staffId: staffId ?? this.staffId,
      serviceCode: serviceCode ?? this.serviceCode,
      startTs: startTs ?? this.startTs,
      endTs: endTs ?? this.endTs,
      status: status ?? this.status,
      billableMinutes: billableMinutes ?? this.billableMinutes,
      billableUnits: billableUnits ?? this.billableUnits,
      notes: notes ?? this.notes,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeIn: timeIn ?? this.timeIn,
    );
  }

  Duration get duration {
    final end = endTs ?? DateTime.now();
    return end.difference(startTs);
  }

  String get durationString {
    final dur = duration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
