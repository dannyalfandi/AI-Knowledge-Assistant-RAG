import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/document.dart';
import 'documents_providers.dart';
import 'status_poller.dart';

/// A single document plus the same poll-while-processing behaviour as the list.
///
/// The detail screen can be opened directly by URL, so it loads its own copy
/// rather than reading from the list controller.
class DocumentDetailState {
  const DocumentDetailState({
    required this.document,
    this.isRefreshing = false,
    this.pollingStoppedMessage,
  });

  final Document document;
  final bool isRefreshing;
  final String? pollingStoppedMessage;

  DocumentDetailState copyWith({
    Document? document,
    bool? isRefreshing,
    String? pollingStoppedMessage,
    bool clearPollingStoppedMessage = false,
  }) {
    return DocumentDetailState(
      document: document ?? this.document,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pollingStoppedMessage: clearPollingStoppedMessage
          ? null
          : pollingStoppedMessage ?? this.pollingStoppedMessage,
    );
  }
}

class DocumentDetailController extends AsyncNotifier<DocumentDetailState> {
  DocumentDetailController(this.documentId);

  final String documentId;

  /// Nullable and rebuilt on every [build]: Riverpod reuses the same notifier
  /// instance across rebuilds (including its automatic retry after a failed
  /// build), so a `late final` here would throw the second time around.
  StatusPoller? _poller;
  DocumentDetailState? _current;

  @override
  Future<DocumentDetailState> build() async {
    _poller?.dispose();
    _current = null;

    final poller = StatusPoller(
      onTick: _fetchInto,
      shouldKeepPolling: () => _current?.document.isProcessing ?? false,
      interval: ref.read(documentsPollIntervalProvider),
      onGaveUp: (message) {
        final current = _current;
        if (current == null) return;
        _emit(
          current.copyWith(isRefreshing: false, pollingStoppedMessage: message),
        );
      },
    );
    _poller = poller;
    ref.onDispose(poller.dispose);

    final document = await ref
        .read(getDocumentUseCaseProvider)
        .call(documentId);
    final initial = DocumentDetailState(document: document);

    _current = initial;
    _poller?.sync();

    return initial;
  }

  Future<void> refresh() async {
    final current = _current;

    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final document = await ref
            .read(getDocumentUseCaseProvider)
            .call(documentId);
        final next = DocumentDetailState(document: document);
        _current = next;
        return next;
      });
      _poller?.reset();
      _poller?.sync();
      return;
    }

    _emit(current.copyWith(isRefreshing: true, clearPollingStoppedMessage: true));
    _poller?.reset();

    try {
      await _fetchInto();
    } finally {
      final latest = _current;
      if (latest != null) _emit(latest.copyWith(isRefreshing: false));
      _poller?.sync();
    }
  }

  /// Triggers processing for this document, with the same optimistic flip the
  /// list uses. Rethrows the backend error after rolling back.
  Future<void> process() async {
    final current = _current;
    if (current == null) return;

    final previous = current.document;
    _emit(
      current.copyWith(
        document: previous.copyWithProcessing(),
        clearPollingStoppedMessage: true,
      ),
    );

    try {
      await ref.read(processDocumentUseCaseProvider).call(documentId);
      _poller?.reset();
      _poller?.sync();
    } catch (_) {
      final latest = _current;
      if (latest != null) _emit(latest.copyWith(document: previous));
      rethrow;
    }
  }

  Future<void> _fetchInto() async {
    final document = await ref
        .read(getDocumentUseCaseProvider)
        .call(documentId);
    final current = _current;

    _emit(
      current == null
          ? DocumentDetailState(document: document)
          : current.copyWith(document: document),
    );
  }

  void _emit(DocumentDetailState next) {
    _current = next;
    state = AsyncData(next);
  }
}

/// Retry is disabled for the same reason as the list provider: the screen shows
/// the error with a "Coba lagi" button, so Riverpod's default exponential retry
/// would only re-request a 403 or a 404 in the background.
final documentDetailControllerProvider =
    AsyncNotifierProvider.autoDispose.family<
      DocumentDetailController,
      DocumentDetailState,
      String
    >(DocumentDetailController.new, retry: (_, _) => null);
