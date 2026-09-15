import 'package:enterprise_knowledge_assistant/core/error/app_exception.dart';
import 'package:enterprise_knowledge_assistant/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:enterprise_knowledge_assistant/features/documents/domain/entities/document.dart';
import 'package:enterprise_knowledge_assistant/features/documents/domain/entities/document_status.dart';
import 'package:enterprise_knowledge_assistant/features/documents/domain/entities/picked_document.dart';
import 'package:enterprise_knowledge_assistant/features/documents/domain/repositories/documents_repository.dart';
import 'package:enterprise_knowledge_assistant/features/documents/presentation/providers/documents_controller.dart';
import 'package:enterprise_knowledge_assistant/features/documents/presentation/providers/documents_providers.dart';
import 'package:enterprise_knowledge_assistant/features/documents/presentation/providers/documents_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _pollInterval = Duration(milliseconds: 10);

Document _document({
  String id = 'doc-1',
  DocumentStatus status = DocumentStatus.pending,
  int chunkCount = 0,
}) {
  return Document(
    id: id,
    originalName: '$id.pdf',
    mimeType: 'application/pdf',
    fileSize: 1024,
    status: status,
    chunkCount: chunkCount,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );
}

class _FakeDocumentsRepository implements DocumentsRepository {
  _FakeDocumentsRepository(this._pages);

  /// One entry per `list()` call; the last entry is reused once exhausted, so a
  /// poll that runs longer than the script keeps seeing the final state.
  final List<List<Document>> _pages;

  int listCalls = 0;
  final List<String> processed = [];
  final List<String> deleted = [];

  Object? processError;
  Object? listError;

  @override
  Future<List<Document>> list() async {
    listCalls++;
    final error = listError;
    if (error != null) throw error;
    return _pages[listCalls - 1 < _pages.length ? listCalls - 1 : _pages.length - 1];
  }

  @override
  Future<Document> getById(String id) async => _document(id: id);

  @override
  Future<Document> upload(
    PickedDocument file, {
    UploadProgressCallback? onProgress,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> process(String id) async {
    final error = processError;
    if (error != null) throw error;
    processed.add(id);
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

ProviderContainer _container(_FakeDocumentsRepository repository) {
  final container = ProviderContainer(
    overrides: [
      documentsRepositoryProvider.overrideWithValue(repository),
      documentsPollIntervalProvider.overrideWithValue(_pollInterval),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Loads the controller and holds a subscription for the rest of the test: the
/// provider is auto-dispose, so without a listener it would be torn down (and
/// its poller cancelled) the moment the initial read completes.
Future<DocumentsState> _load(ProviderContainer container) {
  container.listen(documentsControllerProvider, (_, _) {});
  return container.read(documentsControllerProvider.future);
}

void main() {
  group('loading', () {
    test('exposes the documents returned by the backend', () async {
      final repository = _FakeDocumentsRepository([
        [_document(id: 'a'), _document(id: 'b')],
      ]);
      final container = _container(repository);

      final state = await _load(container);

      expect(state.documents.map((d) => d.id), ['a', 'b']);
      expect(state.hasProcessing, isFalse);
    });

    test('surfaces a backend failure as an error state', () async {
      final repository = _FakeDocumentsRepository([[]])
        ..listError = const ForbiddenException('Forbidden');
      final container = _container(repository);

      await expectLater(_load(container), throwsA(isA<ForbiddenException>()));
    });
  });

  group('polling', () {
    test('does not poll when nothing is PROCESSING', () async {
      final repository = _FakeDocumentsRepository([
        [_document(status: DocumentStatus.indexed, chunkCount: 5)],
      ]);
      final container = _container(repository);

      await _load(container);
      await Future<void>.delayed(_pollInterval * 5);

      expect(repository.listCalls, 1);
    });

    test('refreshes a PROCESSING document until it is INDEXED', () async {
      final repository = _FakeDocumentsRepository([
        [_document(status: DocumentStatus.processing)],
        [_document(status: DocumentStatus.processing)],
        [_document(status: DocumentStatus.indexed, chunkCount: 7)],
      ]);
      final container = _container(repository);

      await _load(container);
      await Future<void>.delayed(_pollInterval * 20);

      final state = container.read(documentsControllerProvider).value!;
      expect(state.documents.single.status, DocumentStatus.indexed);
      expect(state.documents.single.chunkCount, 7);

      // Three list calls: the initial load plus two polls; polling then stops.
      expect(repository.listCalls, 3);

      final callsAfterSettling = repository.listCalls;
      await Future<void>.delayed(_pollInterval * 10);
      expect(repository.listCalls, callsAfterSettling);
    });

    test('a poll never flips the provider back to loading', () async {
      final repository = _FakeDocumentsRepository([
        [_document(status: DocumentStatus.processing)],
        [_document(status: DocumentStatus.indexed)],
      ]);
      final container = _container(repository);

      await _load(container);

      var sawLoading = false;
      container.listen(documentsControllerProvider, (_, next) {
        if (next.isLoading) sawLoading = true;
      });

      await Future<void>.delayed(_pollInterval * 20);
      expect(sawLoading, isFalse);
    });
  });

  group('process', () {
    test('flips the row to PROCESSING optimistically and starts polling', () async {
      final repository = _FakeDocumentsRepository([
        [_document(status: DocumentStatus.pending)],
        [_document(status: DocumentStatus.processing)],
        [_document(status: DocumentStatus.indexed, chunkCount: 3)],
      ]);
      final container = _container(repository);

      await _load(container);
      final notifier = container.read(documentsControllerProvider.notifier);

      await notifier.process('doc-1');

      expect(repository.processed, ['doc-1']);
      expect(
        container.read(documentsControllerProvider).value!.documents.single.status,
        DocumentStatus.processing,
      );

      await Future<void>.delayed(_pollInterval * 20);
      expect(
        container.read(documentsControllerProvider).value!.documents.single.status,
        DocumentStatus.indexed,
      );
    });

    test('rolls the optimistic change back when the backend rejects it', () async {
      final repository = _FakeDocumentsRepository([
        [_document(status: DocumentStatus.pending)],
      ])..processError = const ApiException('Document is already being processed', statusCode: 409);
      final container = _container(repository);

      await _load(container);
      final notifier = container.read(documentsControllerProvider.notifier);

      await expectLater(
        notifier.process('doc-1'),
        throwsA(isA<ApiException>()),
      );

      expect(
        container.read(documentsControllerProvider).value!.documents.single.status,
        DocumentStatus.pending,
      );

      // The rollback must not leave a poll running for a document that never
      // entered PROCESSING.
      await Future<void>.delayed(_pollInterval * 5);
      expect(repository.listCalls, 1);
    });
  });

  group('delete', () {
    test('removes the row only after the backend confirms', () async {
      final repository = _FakeDocumentsRepository([
        [_document(id: 'a'), _document(id: 'b')],
      ]);
      final container = _container(repository);

      await _load(container);
      await container.read(documentsControllerProvider.notifier).delete('a');

      expect(repository.deleted, ['a']);
      expect(
        container.read(documentsControllerProvider).value!.documents.map((d) => d.id),
        ['b'],
      );
    });
  });
}
