part of '../framework.dart';

/// A Scheduler callback.
typedef SchedulerRunner = void Function(void Function());

/// Register a Task Scheduler.
void microTaskSchedulerRunner(void Function() task) {
  Future.microtask(task);
}

/// Scheduler used to dispose/remove pods.
class Scheduler {
  /// [Scheduler] constructor.
  Scheduler({
    SchedulerRunner? postFrameRunner,
  }) : _postFrameRunner = postFrameRunner ?? microTaskSchedulerRunner;

  Listener? _postFrameCallbacks;
  final SchedulerRunner _postFrameRunner;
  bool _postFrameScheduled = false;

  /// Will be run post frame.
  void runPostFrame(void Function() f) {
    _postFrameCallbacks = Listener(
      cb: f,
      next: _postFrameCallbacks,
    );

    if (!_postFrameScheduled) {
      _postFrameScheduled = true;
      _postFrameRunner(_postFrame);
    }
  }

  void _postFrame() {
    _postFrameScheduled = false;

    var listener = _postFrameCallbacks;
    _postFrameCallbacks = null;

    while (listener != null) {
      listener.cb();
      listener = listener.next;
    }
  }
}
