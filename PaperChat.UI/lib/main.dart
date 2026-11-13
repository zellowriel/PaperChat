import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'core/firebase_config.dart';
import 'core/api_client.dart';
import 'data/analytics_repository.dart';
import 'data/auth_repository.dart';
import 'data/paper_chat_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'viewmodels/app_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PaperChatBootstrap());
}

class PaperChatBootstrap extends StatefulWidget {
  const PaperChatBootstrap({super.key});

  @override
  State<PaperChatBootstrap> createState() => _PaperChatBootstrapState();
}

class _PaperChatBootstrapState extends State<PaperChatBootstrap> {
  late final Future<AppViewModel> _initialization = _initialize();

  Future<AppViewModel> _initialize() async {
    await Firebase.initializeApp(options: FirebaseConfig.current);
    final analyticsRepository = FirebaseAnalyticsRepository(
      FirebaseAnalytics.instance,
    );
    final authRepository = FirebaseAuthRepository(FirebaseAuth.instance);
    final repository = ApiPaperChatRepository(
      PaperChatApi(apiBaseUrl, getIdToken: authRepository.getIdToken),
    );
    final viewModel = AppViewModel(
      analyticsRepository: analyticsRepository,
      authRepository: authRepository,
      repository: repository,
    );
    await viewModel.bootstrap();
    return viewModel;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppViewModel>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _StartupError(error: snapshot.error.toString()),
          );
        }
        final viewModel = snapshot.data;
        if (viewModel == null) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _SplashScreen(),
          );
        }
        return PaperChatApp(viewModel: viewModel);
      },
    );
  }
}

class PaperChatApp extends StatefulWidget {
  const PaperChatApp({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<PaperChatApp> createState() => _PaperChatAppState();
}

class _PaperChatAppState extends State<PaperChatApp> {
  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PaperChat AI',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: widget.viewModel.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: widget.viewModel.bootstrapError != null
              ? _StartupError(error: widget.viewModel.bootstrapError!)
              : widget.viewModel.isBootstrapping
              ? const _SplashScreen()
              : widget.viewModel.isSignedIn
              ? MainShell(controller: widget.viewModel)
              : AuthScreen(controller: widget.viewModel),
        );
      },
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44),
              const SizedBox(height: 12),
              const Text(
                'Không thể khởi động PaperChat',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              SelectableText(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
