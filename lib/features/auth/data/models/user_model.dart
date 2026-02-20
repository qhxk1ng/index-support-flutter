import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.phoneNumber,
    required super.name,
    super.email,
    required super.roles,
    required super.activeRole,
    super.isPhoneVerified,
    super.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
      activeRole: json['activeRole'] as String,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'roles': roles,
      'activeRole': activeRole,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      phoneNumber: phoneNumber,
      name: name,
      email: email,
      roles: roles,
      activeRole: activeRole,
      isPhoneVerified: isPhoneVerified,
      createdAt: createdAt,
    );
  }
}
