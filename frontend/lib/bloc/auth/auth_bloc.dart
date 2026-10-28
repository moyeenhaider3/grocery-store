import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_client.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthState.unknown()) {
    // One sequential handler: events are processed strictly in order, so an
    // expired-token logout cannot interleave with a SessionExpired.
    on<AuthEvent>(_onEvent, transformer: (events, mapper) => events.asyncExpand(mapper));
  }

  Future<void> _onEvent(AuthEvent event, Emitter<AuthState> emit) async {
    if (event is AppStarted) return _onAppStarted(emit);
    if (event is LoginRequested) return _onLoginRequested(event, emit);
    if (event is SignupRequested) return _onSignupRequested(event, emit);
    if (event is LogoutRequested) return _onLogoutRequested(emit);
    if (event is SessionExpired) return _onSessionExpired(emit);
    if (event is UserUpdated) return _onUserUpdated(event, emit);
  }

  Future<void> _onUserUpdated(UserUpdated event, Emitter<AuthState> emit) async {
    // Ignored unless authenticated so a late response cannot revive a logged-out session.
    // Also ignored when the response belongs to a different user than the current session.
    if (state.status == AuthStatus.authenticated && state.user?.id == event.user.id) {
      emit(AuthState.authenticated(event.user));
    }
  }

  Future<void> _onAppStarted(Emitter<AuthState> emit) async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } on ApiException catch (e) {
      if (e.endsSession) {
        emit(const AuthState.unauthenticated(sessionExpired: true));
      } else {
        // Cold start / network / 5xx: keep the token, splash offers Retry.
        emit(AuthState.unknown(errorMessage: e.message));
      }
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      final user = await authRepository.login(email: event.email, password: event.password);
      emit(AuthState.authenticated(user));
    } on ApiException catch (e) {
      emit(AuthState.error(e.message));
    }
  }

  Future<void> _onSignupRequested(SignupRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      final user = await authRepository.signup(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(AuthState.authenticated(user));
    } on ApiException catch (e) {
      emit(AuthState.error(e.message));
    }
  }

  Future<void> _onLogoutRequested(Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onSessionExpired(Emitter<AuthState> emit) async {
    if (state.status == AuthStatus.authenticated) {
      emit(const AuthState.unauthenticated(sessionExpired: true));
    }
  }
}
