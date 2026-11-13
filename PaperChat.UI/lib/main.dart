import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/app_config.dart';
import 'core/app_controller.dart';
import 'core/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PaperChatApp(controller: AppController(PaperChatApi(apiBaseUrl))));
}

class PaperChatApp extends StatefulWidget {
  const PaperChatApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<PaperChatApp> createState() => _PaperChatAppState();
}

class _PaperChatAppState extends State<PaperChatApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.bootstrap();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PaperChat AI',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: widget.controller.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: widget.controller.isBootstrapping
              ? const _SplashScreen()
              : widget.controller.isSignedIn
                  ? MainShell(controller: widget.controller)
                  : AuthScreen(controller: widget.controller),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
