import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Signs a user in with email + password.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}
