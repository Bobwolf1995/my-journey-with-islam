import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/auth/presentation/auth_gate.dart';
import 'shared/theme/app_theme.dart';

class RihlatiApp extends StatelessWidget {
  const RihlatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رحلتي مع الإسلام',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}
