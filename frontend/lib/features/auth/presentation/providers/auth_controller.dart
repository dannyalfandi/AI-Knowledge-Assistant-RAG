import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/session_events.dart';
import '../../domain/entities/user.dart';
import 'auth_providers.dart';

/// Owns "who is signed in". [build] runs once at app start and drives the
/// router's redirect guard.
///
/// - [build] resolves the session via `GetCurrentUserUseCase`, which validates
///   the stored token against `GET /api/auth/me`.
/// - [login] runs `LoginUseCase` and, on success, flips the state to the new
///   user (the router then redirects to home). Failures propagate to the caller
///   so the login screen can show the backend message; the state is left
///   untouched so the router does not bounce to the splash screen mid-submit.
/// - A 401 from anywhere (caught by the dio interceptor) ends the session.
class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    ref.listen(sessionExpiredProvider, (_, _) {
      _endSession();
    });

    return ref.read(getCurrentUserUseCaseProvider).call();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final user = await ref
        .read(loginUseCaseProvider)
        .call(email: email, password: password);
    state = AsyncData(user);
  }

  /// Explicit sign-out from the UI.
  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider).call();
    state = const AsyncData(null);
  }

  Future<void> _endSession() async {
    if (state.asData?.value == null) return;
    await ref.read(logoutUseCaseProvider).call();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);
