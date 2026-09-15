import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/admin/presentation/screens/dashboard_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/conversation_list_screen.dart';
import '../../features/documents/presentation/screens/document_detail_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../widgets/forbidden_screen.dart';
import '../widgets/splash_screen.dart';

/// The app router. Its redirect is the single guard for the whole app:
/// unauthenticated users can only reach [LoginScreen], the token check on
/// startup parks everyone on [SplashScreen] until it resolves, and the
/// ADMIN-only areas are gated by role.
///
/// The role check here is a UX affordance — the backend's `authorize("ADMIN")`
/// middleware is the real boundary. It matters on Flutter Web, where a URL can
/// simply be typed in.
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

      final user = auth.asData?.value;

      if (user == null) {
        return location == LoginScreen.path ? null : LoginScreen.path;
      }

      if (location == SplashScreen.path || location == LoginScreen.path) {
        return HomeScreen.path;
      }

      // Document management and the dashboard are ADMIN-only, matching the
      // backend routes that back them.
      const adminOnlyPrefixes = [DocumentsScreen.path, DashboardScreen.path];

      if (!user.isAdmin && adminOnlyPrefixes.any(location.startsWith)) {
        return ForbiddenScreen.path;
      }

      // Don't strand an admin on the "no access" page after a role change.
      if (location == ForbiddenScreen.path && user.isAdmin) {
        return HomeScreen.path;
      }

      return null;
    },
    routes: [
      GoRoute(path: SplashScreen.path, builder: (_, _) => const SplashScreen()),
      GoRoute(path: LoginScreen.path, builder: (_, _) => const LoginScreen()),
      GoRoute(path: HomeScreen.path, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: DashboardScreen.path,
        builder: (_, _) => const DashboardScreen(),
      ),
      GoRoute(
        path: ForbiddenScreen.path,
        builder: (_, _) => const ForbiddenScreen(),
      ),
      GoRoute(
        path: DocumentsScreen.path,
        builder: (_, _) => const DocumentsScreen(),
        routes: [
          GoRoute(
            // Relative to the parent, so the full path is `/documents/:id`.
            path: DocumentDetailScreen.routeSegment,
            builder: (_, state) =>
                DocumentDetailScreen(documentId: state.pathParameters['id']!),
          ),
        ],
      ),
      // Chat is for every signed-in user, not just ADMIN: the backend scopes
      // each conversation to its owner and answers 404 for anyone else's.
      GoRoute(
        path: ConversationListScreen.path,
        builder: (_, _) => const ConversationListScreen(),
        routes: [
          GoRoute(
            // Relative to the parent: `/conversations/:id`.
            path: ChatScreen.routeSegment,
            builder: (_, state) =>
                ChatScreen(conversationId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
