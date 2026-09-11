import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Broadcast channel for "the session is no longer valid".
///
/// The auth interceptor fires this when any request comes back 401 (except the
/// login call itself). The auth controller listens and tears down the session,
/// which makes the router redirect to the login screen. Keeping it in `core`
/// avoids `core` importing a feature.
class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Each call bumps the counter; listeners react to the change.
  void trigger() => state++;
}

final sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, int>(SessionExpiredNotifier.new);
