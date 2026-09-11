import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/documents_repository_impl.dart';
import '../../domain/usecases/delete_document_usecase.dart';
import '../../domain/usecases/get_document_usecase.dart';
import '../../domain/usecases/list_documents_usecase.dart';
import '../../domain/usecases/process_document_usecase.dart';
import '../../domain/usecases/upload_document_usecase.dart';

/// Use-case wiring, kept separate from the controllers (same split as
/// `auth_providers.dart`) so a test can override one use case without
/// rebuilding a controller.
final listDocumentsUseCaseProvider = Provider<ListDocumentsUseCase>((ref) {
  return ListDocumentsUseCase(ref.watch(documentsRepositoryProvider));
});

final getDocumentUseCaseProvider = Provider<GetDocumentUseCase>((ref) {
  return GetDocumentUseCase(ref.watch(documentsRepositoryProvider));
});

final uploadDocumentUseCaseProvider = Provider<UploadDocumentUseCase>((ref) {
  return UploadDocumentUseCase(ref.watch(documentsRepositoryProvider));
});

final processDocumentUseCaseProvider = Provider<ProcessDocumentUseCase>((ref) {
  return ProcessDocumentUseCase(ref.watch(documentsRepositoryProvider));
});

final deleteDocumentUseCaseProvider = Provider<DeleteDocumentUseCase>((ref) {
  return DeleteDocumentUseCase(ref.watch(documentsRepositoryProvider));
});

/// How often a `PROCESSING` document is re-checked.
///
/// Exposed as a provider rather than hardcoded inside the controllers so it is
/// named in one place and can be overridden (tests shorten it; a deployment
/// could tune it without touching the controllers).
final documentsPollIntervalProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 3);
});
