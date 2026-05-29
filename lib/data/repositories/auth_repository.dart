import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AuthRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<UserAccount> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    final existingUser = await dbHelper.getUserByEmail(email.toLowerCase());

    if (existingUser != null) {
      throw AuthException('Пользователь с таким email уже существует');
    }

    final user = {
      'id': const Uuid().v4(),
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password_hash': password,
      'role': role.stringValue,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    await dbHelper.insertUser(user);

    return UserAccount(
      id: user['id'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
      role: role,
      createdAt: DateTime.fromMillisecondsSinceEpoch(user['created_at'] as int),
    );
  }

  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    final user = await dbHelper.getUserByEmail(email.trim().toLowerCase());

    if (user == null) {
      throw AuthException('Неверный email или пароль');
    }

    if (password.isEmpty || user['password_hash'] != password) {
      throw AuthException('Неверный email или пароль');
    }

    return UserAccount(
      id: user['id'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
      role: user['role'] == 'admin' ? UserRole.admin : UserRole.user,
      createdAt: DateTime.fromMillisecondsSinceEpoch(user['created_at'] as int),
    );
  }

  Future<UserAccount?> getUserById(String id) async {
    final user = await dbHelper.getUserById(id);
    if (user == null) return null;

    return UserAccount(
      id: user['id'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
      role: user['role'] == 'admin' ? UserRole.admin : UserRole.user,
      createdAt: DateTime.fromMillisecondsSinceEpoch(user['created_at'] as int),
    );
  }

  Future<bool> hasAnyUsers() async {
    return await dbHelper.hasAnyUsers();
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
