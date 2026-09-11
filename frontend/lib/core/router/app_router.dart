import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../widgets/splash_screen.dart';

/// The app router. Its redirect is the single auth guard: unauthenticated users
/// can only reach [LoginScreen], and the token check on startup parks everyone
/// on [SplashScreen] until it resolves.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: SplashScreen.path,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      if (auth.isLoading) {
        return location == SplashScreen.path ? null : SplashScreen.path;
      }

      final signedIn = auth.asData?.value != null;

      if (!signedIn) {
        return location == LoginScreen.path ? null : LoginScreen.path;
      }

      if (location == SplashScreen.path || location == LoginScreen.path) {
        return HomeScreen.path;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.path,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.path,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: HomeScreen.path,
        builder: (_, _) => const HomeScreen(),
      ),
    ],
  );
});
