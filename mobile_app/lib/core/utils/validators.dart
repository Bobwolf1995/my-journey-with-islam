class Validators {
  const Validators._();

  static String? requiredField(
    String? value, {
    String message = 'هذا الحقل مطلوب',
  }) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  static String? name(String? value) {
    final requiredError = requiredField(
      value,
      message: 'الاسم مطلوب',
    );

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 2) {
      return 'الاسم قصير جدًا';
    }

    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(
      value,
      message: 'البريد الإلكتروني مطلوب',
    );

    if (requiredError != null) {
      return requiredError;
    }

    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailRegex.hasMatch(value!.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }

    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredField(
      value,
      message: 'كلمة المرور مطلوبة',
    );

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }

    return null;
  }

  static String? confirmPassword(
    String? value, {
    required String passwordValue,
  }) {
    final requiredError = requiredField(
      value,
      message: 'تأكيد كلمة المرور مطلوب',
    );

    if (requiredError != null) {
      return requiredError;
    }

    if (value != passwordValue) {
      return 'كلمتا المرور غير متطابقتين';
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.trim().replaceAll(RegExp(r'[\s\-]'), '');

    if (normalized.length < 7) {
      return 'رقم الهاتف قصير جدًا';
    }

    final phoneRegex = RegExp(r'^\+?[0-9]+$');

    if (!phoneRegex.hasMatch(normalized)) {
      return 'رقم الهاتف غير صحيح';
    }

    return null;
  }
}
