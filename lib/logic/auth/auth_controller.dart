import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

class AuthState {
  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.isInitializing = true,
  });

  final UserAccount? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitializing;

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    UserAccount? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool? isInitializing,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState()) {
    _init();
  }

  final AuthRepository _repo;

  Future<void> _init() async {
    state = state.copyWith(isInitializing: true);
    final hasUsers = await _repo.hasAnyUsers();
    
    if (!hasUsers) {
      await _repo.register(
        name: 'Администратор',
        email: 'admin@example.com',
        password: 'admin123',
        role: UserRole.admin,
      );
      await _repo.register(
        name: 'Пользователь',
        email: 'user@example.com',
        password: 'user123',
        role: UserRole.user,
      );
    }
    
    state = state.copyWith(isInitializing: false);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.register(
        name: name, 
        email: email, 
        password: password,
        role: role,
      );
      state = AuthState(currentUser: user, isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Ошибка регистрации');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthState(currentUser: user, isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Ошибка авторизации');
    }
  }

  void logout() {
    state = const AuthState();
  }

  bool get canManageProducts => state.currentUser?.role.canManageProducts ?? false;
}