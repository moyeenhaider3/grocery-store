import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class SignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const SignupRequested({required this.name, required this.email, required this.password});
  @override
  List<Object?> get props => [name, email, password];
}

class LogoutRequested extends AuthEvent {}

class SessionExpired extends AuthEvent {}

class UserUpdated extends AuthEvent {
  final UserModel user;
  const UserUpdated(this.user);
  @override
  List<Object?> get props => [user];
}
