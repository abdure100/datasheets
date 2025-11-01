import 'package:json_annotation/json_annotation.dart';

part 'session_record.g.dart';

@JsonSerializable()
class SessionRecord {
  @JsonKey(name: 'PrimaryKey')
  final String id;
  
  @JsonKey(name: 'visitId')
  final String visitId;
  
  @JsonKey(name: 'clientId')
  final String clientId;
  
  @JsonKey(name: 'assignmentId')
  final String assignmentId;
  
  @JsonKey(name: 'startedAt_ts', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? startedAt;
  
  @JsonKey(name: 'updatedAt_ts', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? updatedAt;
  
  @JsonKey(name: 'payload_json')
  final Map<String, dynamic> payload;
  
  @JsonKey(name: 'notes')
  final String? notes;
  
  @JsonKey(name: 'staffId')
  final String? staffId;
  
  @JsonKey(name: 'intervention_phase')
  final String? interventionPhase;
  
  @JsonKey(name: 'program_start_time', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? programStartTime;
  
  @JsonKey(name: 'program_end_time', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? programEndTime;

  @JsonKey(name: 'Company')
  final String? company;

  const SessionRecord({
    required this.id,
    required this.visitId,
    required this.clientId,
    required this.assignmentId,
    this.startedAt,
    this.updatedAt,
    required this.payload,
    this.notes,
    this.staffId,
    this.interventionPhase,
    this.programStartTime,
    this.programEndTime,
    this.company,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> json) => _$SessionRecordFromJson(json);
  Map<String, dynamic> toJson() => _$SessionRecordToJson(this);

  SessionRecord copyWith({
    String? id,
    String? visitId,
    String? clientId,
    String? assignmentId,
    DateTime? startedAt,
    DateTime? updatedAt,
    Map<String, dynamic>? payload,
    String? notes,
    String? staffId,
    String? interventionPhase,
    DateTime? programStartTime,
    DateTime? programEndTime,
    String? company,
  }) {
    return SessionRecord(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      clientId: clientId ?? this.clientId,
      assignmentId: assignmentId ?? this.assignmentId,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payload: payload ?? this.payload,
      notes: notes ?? this.notes,
      staffId: staffId ?? this.staffId,
      interventionPhase: interventionPhase ?? this.interventionPhase,
      programStartTime: programStartTime ?? this.programStartTime,
      programEndTime: programEndTime ?? this.programEndTime,
      company: company ?? this.company,
    );
  }

  // Helper functions for DateTime conversion
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

  static String _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String() ?? '';
  }
}
