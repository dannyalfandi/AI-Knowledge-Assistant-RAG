import 'package:enterprise_knowledge_assistant/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson reads the full login payload', () {
    final model = UserModel.fromJson({
      'id': 'u1',
      'email': 'a@b.com',
      'name': 'Admin',
      'role': 'ADMIN',
    });

    expect(model.id, 'u1');
    expect(model.email, 'a@b.com');
    expect(model.name, 'Admin');
    expect(model.isAdmin, isTrue);
  });

  test('fromJson tolerates the partial /me payload (id + role only)', () {
    final model = UserModel.fromJson({'id': 'u1', 'role': 'USER'});

    expect(model.email, isEmpty);
    expect(model.name, isEmpty);
    expect(model.isAdmin, isFalse);
  });

  test('encode / tryDecode round-trip', () {
    const model = UserModel(
      id: 'u1',
      email: 'a@b.com',
      name: 'Admin',
      role: 'ADMIN',
    );

    final decoded = UserModel.tryDecode(model.encode());

    expect(decoded, isNotNull);
    expect(decoded!.email, 'a@b.com');
    expect(decoded.role, 'ADMIN');
  });

  test('tryDecode returns null on invalid input', () {
    expect(UserModel.tryDecode('not json'), isNull);
    expect(UserModel.tryDecode(null), isNull);
    expect(UserModel.tryDecode(''), isNull);
  });
}
