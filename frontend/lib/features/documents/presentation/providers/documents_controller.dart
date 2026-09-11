import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'documents_providers.dart';
import 'documents_state.dart';
import 'status_poller.dart';

/// Owns the documents list and the polling that keeps `PROCESSING` rows fresh.
///
/// Polling is driven by the data, not by the UI: after every load, if any
/// document is `PROCESSING` the poller schedules another silent fetch; once
/// none are, it stops on its own. The provider is auto-dispose, so leaving the
/// screen tears the timer down too.
class DocumentsController extends AsyncNotifier<DocumentsState> {
  /// Nullable and rebuilt on every [build]: Riverpod reuses the same notifier
  /// instance across rebuilds (including its automatic retry after a failed
  /// build), so a `late final` here would throw the second time around.
  StatusPoller? _poller;

  /// Mirrors the last emitted value. `state` cannot be read or written while
  /// [build] is still running, and the poller callbacks need a snapshot that is
  /// valid at every point in the lifecycle.
  DocumentsState? _current;

  @override
  Future<DocumentsState> build() async {
    _poller?.dispose();
    _current = null;

    final poller = StatusPoller(
      onTick: _fetchInto,
      shouldKeepPolling: () => _current?.hasProcessing ?? false,
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

    final documents = await ref.read(listDocumentsUseCaseProvider).call();
    final initial = DocumentsState(documents: documents);

    _current = initial;
    _poller?.sync();

    return initial;
  }

  /// Manual refresh. Keeps the current list on screen while the request is in
  /// flight instead of falling back to a full-screen spinner.
  Future<void> refresh() async {
    final current = _current;

    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final documents = await ref.read(listDocumentsUseCaseProvider).call();
        final next = DocumentsState(documents: documents);
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

  /// Asks the backend to (re)index [id]. Flips the row to `PROCESSING`
  /// optimistically so the UI reacts immediately, then lets polling take over.
  ///
  /// Rethrows the backend error (e.g. 409 when it is already processing) after
  /// rolling the optimistic change back, so the screen can show the message.
  Future<void> process(String id) async {
    final current = _current;
    if (current == null) return;

    final previous = current.documents;
    _emit(
      current.copyWith(
        documents: [
          for (final document in previous)
            if (document.id == id) document.copyWithProcessing() else document,
        ],
        clearPollingStoppedMessage: true,
      ),
    );

    try {
      await ref.read(processDocumentUseCaseProvider).call(id);
      _poller?.reset();
      _poller?.sync();
    } catch (_) {
      final latest = _current;
      if (latest != null) _emit(latest.copyWith(documents: previous));
      rethrow;
    }
  }

  /// Deletes [id] on the backend, then drops it from the list. Rethrows on
  /// failure; nothing is removed optimistically, because a row that silently
  /// reappears is worse than a short wait.
  Future<void> delete(String id) async {
    await ref.read(deleteDocumentUseCaseProvider).call(id);

    final current = _current;
    if (current == null) return;

    _emit(
      current.copyWith(
        documents: current.documents
            .where((document) => document.id != id)
            .toList(growable: false),
      ),
    );
    _poller?.sync();
  }

  /// Called after a successful upload. The upload response carries only a
  /// subset of the row, so the whole list is reloaded instead of patched.
  Future<void> reloadAfterUpload() => refresh();

  /// One silent fetch: replaces the documents without ever going through
  /// `AsyncLoading`, so the list neither blinks nor loses scroll position.
  Future<void> _fetchInto() async {
    final documents = await ref.read(listDocumentsUseCaseProvider).call();
    final current = _current;

    _emit(
      current == null
          ? DocumentsState(documents: documents)
          : current.copyWith(documents: documents),
    );
  }

  void _emit(DocumentsState next) {
    _current = next;
    state = AsyncData(next);
  }
}

/// Retry is disabled: a failed load surfaces an error with a "Coba lagi"
/// button, and Riverpod's default exponential retry would otherwise keep
/// re-requesting a 403 (a non-ADMIN) or a 500 in the background.
final documentsControllerProvider =
    AsyncNotifierProvider.autoDispose<DocumentsController, DocumentsState>(
      DocumentsController.new,
      retry: (_, _) => null,
    );
