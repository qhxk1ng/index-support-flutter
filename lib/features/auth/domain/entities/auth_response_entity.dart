import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class AuthResponseEntity extends Equatable {
  final String token;
  final UserEntity user;
  
  const AuthResponseEntity({
    required this.token,
    required this.user,
  });
  
  @override
  List<Object> get props => [token, user];
}
