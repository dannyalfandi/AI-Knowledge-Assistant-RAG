import 'package:enterprise_knowledge_assistant/features/documents/presentation/providers/status_poller.dart';
import 'package:flutter_test/flutter_test.dart';

const _interval = Duration(milliseconds: 10);

void main() {
  test('does not schedule anything when nothing is processing', () async {
    var ticks = 0;

    final poller = StatusPoller(
      onTick: () async => ticks++,
      shouldKeepPolling: () => false,
      onGaveUp: (_) => fail('should not give up'),
      interval: _interval,
    );
    addTearDown(poller.dispose);

    poller.sync();

    expect(poller.isActive, isFalse);
    await Future<void>.delayed(_interval * 5);
    expect(ticks, 0);
  });

  test('keeps ticking while processing, then stops on its own', () async {
    var ticks = 0;

    // Mimics a document that finishes after the third poll.
    var stillProcessing = true;

    final poller = StatusPoller(
      onTick: () async {
        ticks++;
        if (ticks >= 3) stillProcessing = false;
      },
      shouldKeepPolling: () => stillProcessing,
      onGaveUp: (_) => fail('should not give up'),
      interval: _interval,
    );
    addTearDown(poller.dispose);

    poller.sync();
    await Future<void>.delayed(_interval * 20);

    expect(ticks, 3);
    expect(poller.isActive, isFalse);
  });

  test('gives up once maxTicks is exceeded (document stuck PROCESSING)', () async {
    var ticks = 0;
    String? gaveUpMessage;

    final poller = StatusPoller(
      onTick: () async => ticks++,
      shouldKeepPolling: () => true,
      onGaveUp: (message) => gaveUpMessage = message,
      interval: _interval,
      maxTicks: 3,
    );
    addTearDown(poller.dispose);

    poller.sync();
    await Future<void>.delayed(_interval * 30);

    expect(ticks, 3);
    expect(gaveUpMessage, isNotNull);
    expect(poller.isActive, isFalse);
  });

  test('gives up after repeated failures instead of retrying forever', () async {
    var attempts = 0;
    String? gaveUpMessage;

    final poller = StatusPoller(
      onTick: () async {
        attempts++;
        throw Exception('backend unreachable');
      },
      shouldKeepPolling: () => true,
      onGaveUp: (message) => gaveUpMessage = message,
      interval: _interval,
      maxConsecutiveFailures: 2,
    );
    addTearDown(poller.dispose);

    poller.sync();
    await Future<void>.delayed(_interval * 30);

    expect(attempts, 2);
    expect(gaveUpMessage, isNotNull);
    expect(poller.isActive, isFalse);
  });

  test('reset clears the give-up latch so a new run can be watched', () async {
    var ticks = 0;

    final poller = StatusPoller(
      onTick: () async => ticks++,
      shouldKeepPolling: () => true,
      onGaveUp: (_) {},
      interval: _interval,
      maxTicks: 1,
    );
    addTearDown(poller.dispose);

    poller.sync();
    await Future<void>.delayed(_interval * 10);
    expect(ticks, 1);

    // Without reset, sync() is a no-op after giving up.
    poller.sync();
    await Future<void>.delayed(_interval * 5);
    expect(ticks, 1);

    poller.reset();
    poller.sync();
    await Future<void>.delayed(_interval * 10);
    expect(ticks, 2);
  });

  test('dispose stops a scheduled tick', () async {
    var ticks = 0;

    final poller = StatusPoller(
      onTick: () async => ticks++,
      shouldKeepPolling: () => true,
      onGaveUp: (_) {},
      interval: _interval,
    );

    poller.sync();
    poller.dispose();

    await Future<void>.delayed(_interval * 5);
    expect(ticks, 0);
  });
}
