class ApiEndpoints {
  const ApiEndpoints._();

  static const String health = '';

  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String me = '/api/auth/me';
  static const String logout = '/api/auth/logout';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  static const String profile = '/api/profile';

  static const String notifications = '/api/notifications';

  static String notificationRead(int notificationId) {
    return '/api/notifications/$notificationId/read';
  }

  static const String conversations = '/api/conversations';

  static String conversationMessages(int conversationId) {
    return '/api/conversations/$conversationId/messages';
  }

  static const String home = '/api/home';
  static const String courses = '/api/courses';
  static const String learningPaths = '/api/learning-paths';
  static const String library = '/api/library';
  static const String community = '/api/community';
  static const String tasks = '/api/tasks';
  static const String favorites = '/api/favorites';
  static const String favoritesToggle = '/api/favorites/toggle';
  static const String badges = '/api/badges';
  static const String badgesMy = '/api/badges/my';
  static const String aiAsk = '/api/ai/ask';

  static String quizSubmit(int quizId) {
    return '/api/quizzes/$quizId/submit';
  }
}
