import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

class AuthState {
	const AuthState({
		this.currentUser,
		this.isLoading = false,
		this.errorMessage,
	});

	final UserAccount? currentUser;
	final bool isLoading;
	final String? errorMessage;

	AuthState copyWith({
		UserAccount? currentUser,
		bool? isLoading,
		String? errorMessage,
	}) {
		return AuthState(
			currentUser: currentUser ?? this.currentUser,
			isLoading: isLoading ?? this.isLoading,
			errorMessage: errorMessage,
		);
	}
}

class AuthController extends StateNotifier<AuthState> {
	AuthController(this._repo) : super(const AuthState());

	final AuthRepository _repo;

	Future<void> register({
		required String name,
		required String email,
		required String password,
	}) async {
		state = state.copyWith(isLoading: true, errorMessage: null);
		try {
			final user = await _repo.register(name: name, email: email, password: password);
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
}

