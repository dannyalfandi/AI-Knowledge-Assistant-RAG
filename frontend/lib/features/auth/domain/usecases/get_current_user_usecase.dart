import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Resolves the signed-in user on app start (validates the stored token against
/// the backend). Returns `null` when there is no valid session.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<User?> call() => _repository.currentUser();
}
