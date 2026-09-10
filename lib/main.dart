import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart' as di;
import 'core/navigation/app_navigator.dart';
import 'core/services/background_location_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/network_status_banner.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/permissions_onboarding_page.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await di.init();
  
  // Initialize services with error handling — don't let failures
  // prevent the app from starting
  try {
    await BackgroundLocationService.initialize();
  } catch (_) {
    // Background location service init failed — app can still work
  }
  
  try {
    await ConnectivityService.instance.start();
  } catch (_) {
    // Connectivity monitoring failed — app can still work
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: BlocProvider(
        create: (context) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              navigatorKey: AppNavigator.key,
              title: 'Index Care',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              builder: (context, child) =>
                  NetworkStatusBanner(child: child ?? const SizedBox.shrink()),
              routes: {
                '/home': (context) => const HomePage(),
                '/login': (context) => const LoginPage(),
              },
              home: PermissionsOnboardingPage(
                child: BlocConsumer<AuthBloc, AuthState>(
                  listenWhen: (previous, current) {
                    // Navigate only on real auth state transitions
                    return (previous is AuthAuthenticated && current is AuthUnauthenticated) ||
                           (previous is! AuthAuthenticated && current is AuthAuthenticated);
                  },
                  listener: (context, state) {
                    if (state is AuthUnauthenticated) {
                      AppNavigator.navigateToLogin();
                    } else if (state is AuthAuthenticated) {
                      AppNavigator.navigateToHome();
                    }
                  },
                  buildWhen: (previous, current) {
                    // Only rebuild root widget if auth status fundamentally changes
                    // Never rebuild or unmount active screens on transient action loading/errors!
                    if (previous is AuthInitial) return true;
                    if (previous is! AuthAuthenticated && current is AuthAuthenticated) return true;
                    if (previous is AuthAuthenticated && current is AuthUnauthenticated) return true;
                    if (previous is AuthLoading &&
                        (current is AuthAuthenticated ||
                         current is AuthUnauthenticated ||
                         current is AuthError)) {
                      return true;
                    }
                    return false;
                  },
                  builder: (context, state) {
                    if (state is AuthAuthenticated) {
                      return const HomePage();
                    } else if (state is AuthUnauthenticated || state is AuthError) {
                      return const LoginPage();
                    }
                    // Show initial launch splash spinner while checking auth status
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
