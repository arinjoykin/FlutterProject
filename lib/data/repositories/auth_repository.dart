import 'package:uuid/uuid.dart';
import '../models/user.dart';

class AuthRepository {
  final Map<String, UserAccount> _emailToUser = {};
  final _uuid = const Uuid();

  Future<UserAccount> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_emailToUser.containsKey(email.toLowerCase())) {
      throw AuthException('Пользователь с таким email уже существует');
    }

    final user = UserAccount(
      id: _uuid.v4(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );
    _emailToUser[user.email] = user;
    return user;
  }

  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final user = _emailToUser[email.trim().toLowerCase()];
    if (user == null) {
      throw AuthException('Неверный email или пароль');
    }
    return user;
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
