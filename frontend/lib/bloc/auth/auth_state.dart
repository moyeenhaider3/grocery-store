import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool sessionExpired;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.sessionExpired = false,
  });

  const AuthState.unknown({String? errorMessage}) : this(status: AuthStatus.unknown, errorMessage: errorMessage);
  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.authenticated(UserModel user) : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated({bool sessionExpired = false})
      : this(status: AuthStatus.unauthenticated, sessionExpired: sessionExpired);
  const AuthState.error(String message) : this(status: AuthStatus.error, errorMessage: message);

  @override
  List<Object?> get props => [status, user, errorMessage, sessionExpired];
}
