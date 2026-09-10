import 'package:flutter/material.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => key.currentContext;

  static void navigateToLogin() {
    key.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  static void navigateToHome() {
    key.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
  }
}
