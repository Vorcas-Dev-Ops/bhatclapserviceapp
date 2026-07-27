import 'package:flutter/material.dart';
import '../screens/service_unavailable_screen.dart';

class ServerErrorHandler {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static bool _isShowing503Screen = false;

  /// Trigger 503 error screen if server is unreachable or returning 503
  static void handle503Error({String? message, VoidCallback? onRetry}) {
    if (_isShowing503Screen) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isShowing503Screen = true;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceUnavailableScreen(
          message: message,
          onRetry: () {
            _isShowing503Screen = false;
            if (onRetry != null) {
              onRetry();
            }
          },
        ),
      ),
    ).then((_) {
      _isShowing503Screen = false;
    });
  }
}
