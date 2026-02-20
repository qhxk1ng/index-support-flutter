import '../../domain/entities/auth_response_entity.dart';
import 'user_model.dart';

class AuthResponseModel extends AuthResponseEntity {
  const AuthResponseModel({
    required super.token,
    required super.user,
  });
  
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': (user as UserModel).toJson(),
    };
  }
  
  AuthResponseEntity toEntity() {
    return AuthResponseEntity(
      token: token,
      user: user,
    );
  }
}
