import 'dart:async';

/// Re-runs [onTick] on a fixed interval for as long as [shouldKeepPolling]
/// says there is something worth watching.
///
/// The backend processes documents in a detached async task (`POST
/// /api/documents/:id/process` answers 202 immediately), so the only way for
/// the client to learn that a `PROCESSING` document finished is to ask again.
/// Two stop conditions keep that from running forever:
///
///  - [maxTicks] — a document can get stuck at `PROCESSING` permanently if the
///    backend process dies mid-run, since nothing would then move it to
///    `FAILED`. After roughly [maxTicks] × [interval] we give up and let the UI
///    ask the user to refresh manually.
///  - [maxConsecutiveFailures] — when the backend is unreachable, retrying
///    every few seconds forever only adds noise.
///
/// Ticks are scheduled one at a time (never `Timer.periodic`) so a slow
/// response can't queue overlapping requests.
class StatusPoller {
  StatusPoller({
    required this.onTick,
    required this.shouldKeepPolling,
    required this.onGaveUp,
    this.interval = const Duration(seconds: 3),
    this.maxTicks = 60,
    this.maxConsecutiveFailures = 3,
  });

  /// Performs one refresh. Throwing counts as a failed tick.
  final Future<void> Function() onTick;

  /// Evaluated after every tick: `true` while something is still `PROCESSING`.
  final bool Function() shouldKeepPolling;

  /// Called once when polling stops for a reason other than "nothing left to
  /// watch". [message] is safe to show in the UI.
  final void Function(String message) onGaveUp;

  final Duration interval;
  final int maxTicks;
  final int maxConsecutiveFailures;

  Timer? _timer;
  int _ticks = 0;
  int _consecutiveFailures = 0;
  bool _gaveUp = false;
  bool _disposed = false;

  bool get isActive => _timer != null;

  /// Starts or stops polling to match the current data. Call this after every
  /// state change that could add or remove a `PROCESSING` document.
  void sync() {
    if (_disposed || _gaveUp) return;

    if (!shouldKeepPolling()) {
      _cancelTimer();
      _ticks = 0;
      _consecutiveFailures = 0;
      return;
    }

    _timer ??= Timer(interval, _tick);
  }

  /// Clears the give-up latch so a newly triggered process can be watched again
  /// even if an earlier one timed out.
  void reset() {
    _gaveUp = false;
    _ticks = 0;
    _consecutiveFailures = 0;
  }

  void dispose() {
    _disposed = true;
    _cancelTimer();
  }

  Future<void> _tick() async {
    _timer = null;
    if (_disposed) return;

    _ticks++;
    if (_ticks > maxTicks) {
      _giveUp(
        'Dokumen masih diproses lebih lama dari biasanya. Pembaruan otomatis '
        'dihentikan — muat ulang untuk melihat status terbaru.',
      );
      return;
    }

    try {
      await onTick();
      _consecutiveFailures = 0;
    } catch (_) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= maxConsecutiveFailures) {
        _giveUp(
          'Gagal memperbarui status dari server. Pembaruan otomatis '
          'dihentikan — periksa koneksi lalu muat ulang.',
        );
        return;
      }
    }

    if (_disposed) return;
    sync();
  }

  void _giveUp(String message) {
    _gaveUp = true;
    _cancelTimer();
    if (!_disposed) onGaveUp(message);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
