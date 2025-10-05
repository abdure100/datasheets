import 'package:json_annotation/json_annotation.dart';

part 'staff.g.dart';

@JsonSerializable()
class Staff {
  @JsonKey(name: 'PrimaryKey')
  final String id;
  @JsonKey(name: 'email')
  final String email;
  @JsonKey(name: 'Password_raw')
  final String passwordRaw;
  @JsonKey(name: 'FullName')
  final String name;
  @JsonKey(name: 'role')
  final String? role;
  @JsonKey(name: 'active')
  final bool? active;

  const Staff({
    required this.id,
    required this.email,
    required this.passwordRaw,
    required this.name,
    this.role,
    this.active,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
  Map<String, dynamic> toJson() => _$StaffToJson(this);

  @override
  String toString() => name;
}
