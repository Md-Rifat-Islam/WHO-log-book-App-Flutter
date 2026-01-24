import 'dart:async';
import 'package:flutter/foundation.dart';

/// Allows GoRouter to refresh when a Stream emits (e.g., FirebaseAuth authStateChanges()).
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
