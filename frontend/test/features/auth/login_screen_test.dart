import 'package:enterprise_knowledge_assistant/core/error/app_exception.dart';
import 'package:enterprise_knowledge_assistant/features/auth/domain/entities/user.dart';
import 'package:enterprise_knowledge_assistant/features/auth/domain/repositories/auth_repository.dart';
import 'package:enterprise_knowledge_assistant/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:enterprise_knowledge_assistant/features/auth/domain/usecases/login_usecase.dart';
import 'package:enterprise_knowledge_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:enterprise_knowledge_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  Object? loginError;
  User? loginUser;

  @override
  Future<User> login({required String email, required String password}) async {
    final error = loginError;
    if (error != null) throw error;
    return loginUser!;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User?> currentUser() async => null;
}

Widget _wrap(_FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [
      loginUseCaseProvider.overrideWithValue(LoginUseCase(repository)),
      getCurrentUserUseCaseProvider
          .overrideWithValue(GetCurrentUserUseCase(repository)),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  testWidgets('validates empty fields before calling the use case', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeAuthRepository()));

    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('shows the backend message when login is rejected', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..loginError = const UnauthorizedException('Invalid email or password');

    await tester.pumpWidget(_wrap(repository));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'admin@corp.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
  });
}
