// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Client _$ClientFromJson(Map<String, dynamic> json) => Client(
      id: json['PrimaryKey'] as String,
      name: json['namefull'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['Email'] as String?,
      agencyId: json['Company'] as String?,
      dateOfBirth: json['dob'] as String?,
    );

Map<String, dynamic> _$ClientToJson(Client instance) => <String, dynamic>{
      'PrimaryKey': instance.id,
      'namefull': instance.name,
      'address': instance.address,
      'phone': instance.phone,
      'Email': instance.email,
      'Company': instance.agencyId,
      'dob': instance.dateOfBirth,
    };
