import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String phoneNumber;
  final String name;
  final String? email;
  final List<String> roles;
  final String activeRole;
  final bool isPhoneVerified;
  final DateTime? createdAt;
  
  const UserEntity({
    required this.id,
    required this.phoneNumber,
    required this.name,
    this.email,
    required this.roles,
    required this.activeRole,
    this.isPhoneVerified = false,
    this.createdAt,
  });
  
  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        name,
        email,
        roles,
        activeRole,
        isPhoneVerified,
        createdAt,
      ];
}
