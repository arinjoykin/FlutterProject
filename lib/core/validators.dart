class Validators {
	static String? requiredField(String? value, {String fieldName = 'Поле'}) {
		if (value == null || value.trim().isEmpty) {
			return '$fieldName обязательно для заполнения';
		}
		return null;
	}

	static String? email(String? value) {
		final v = value?.trim() ?? '';
		if (v.isEmpty) return 'Email обязателен';
		final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
		if (!emailRegex.hasMatch(v)) return 'Некорректный email';
		return null;
	}

	static String? password(String? value, {int minLen = 6}) {
		final v = value ?? '';
		if (v.length < minLen) return 'Минимальная длина пароля: $minLen';
		return null;
	}

	static String? confirmPassword(String? value, String original) {
		if (value != original) return 'Пароли не совпадают';
		return null;
	}
}