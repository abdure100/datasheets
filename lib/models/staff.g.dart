// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Staff _$StaffFromJson(Map<String, dynamic> json) => Staff(
      id: json['PrimaryKey'] as String,
      email: json['email'] as String,
      passwordRaw: json['Password_raw'] as String,
      name: json['FullName'] as String,
      role: json['role'] as String?,
      active: _boolFromJson(json['active']),
      allowManualEntry: _intFromJson(json['Allow_manual_entry']),
    );

Map<String, dynamic> _$StaffToJson(Staff instance) => <String, dynamic>{
      'PrimaryKey': instance.id,
      'email': instance.email,
      'Password_raw': instance.passwordRaw,
      'FullName': instance.name,
      'role': instance.role,
      'active': instance.active,
      'Allow_manual_entry': instance.allowManualEntry,
    };
