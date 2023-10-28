// ignore_for_file: prefer_asserts_with_message

part of '../framework.dart';

/// Responsible for mapping pod's to their state.
///
/// Each pod corresponds to a [Node], which contains the current state for that
/// pod.
class PodContainer {
  /// Container constructor.
  PodContainer({
    List<Override<dynamic>> overrides = const [],
  }) {
    for (final override in overrides) {
      _ensureNode(override.pod).setValue(override.value);
    }
  }

  final Scheduler _scheduler = Scheduler();

  /// The state map, where each pod has a corresponding [Node].
  final nodes = HashMap<Pod<dynamic>, Node?>();

  /// Retrieve the state for the given [Pod], creating or rebuilding it when
  /// required.
  T get<T>(Pod<T> pod) => _ensureNode(pod).value as T;

  /// Set the state of a [WritablePod].
  void set<T, V>(WritablePodBase<T, V> pod, V value) =>
      pod.write(get, set, _ensureNode(pod).setValue, value);

  /// Manually recalculate a [pod]'s value.
  void refresh(RefreshablePod pod) => pod.refresh(_refresh);

  /// Listen to changes of a pod's state.
  ///
  /// Call [get] to retrieve the latest value after the [handler] is called.
  void Function() subscribe<T>(
    Pod<dynamic> pod,
    void Function(T value) handler, {
    bool fireImmediately = false,
  }) {
    final node = _ensureNode(pod);
    final remove = node.addListener(() {
      handler(node._value as T);
    });

    if (fireImmediately) {
      if (!node.state.initialized) {
        node.value;
      } else {
        handler(node.value as T);
      }
    }

    return () {
      remove();
      if (node.canBeRemoved) {
        _scheduler.runPostFrame(() {
          if (!node.canBeRemoved) return;
          _removeNode(node);
        });
      }
    };
  }

  /// Listen to changes of a pod's state, and retrieve the latest value.
  void Function() subscribeWithPrevious<T>(
    Pod<T> pod,
    void Function(T? previous, T value) handler, {
    bool fireImmediately = false,
  }) {
    final node = _ensureNode(pod);

    var previousValue = node._value as T?;

    return subscribe(
      pod,
      (T nextValue) {
        handler(previousValue, nextValue);
        previousValue = nextValue;
      },
      fireImmediately: fireImmediately,
    );
  }

  /// Listen to a [pod], run the given [cb] (which can return a [Future]),
  /// then remove the listener once the [cb] is complete.
  Future<T> use<T>(Pod<dynamic> pod, FutureOr<T> Function() cb) async {
    final remove = mount(pod);

    try {
      return await cb();
    } finally {
      remove();
    }
  }

  /// Listen to a [pod], but don't register a handler function.
  ///
  /// Returns a function which 'unmounts' the [pod].
  void Function() mount(Pod<dynamic> pod) =>
      subscribe(pod, (_) {}, fireImmediately: true);

  /// Listen to a [pod] as a [Stream].
  Stream<T> stream<T>(Pod<T> pod) {
    late StreamController<T> controller;
    void Function()? cancel;

    void pause() {
      cancel?.call();
      cancel = null;
    }

    void resume() {
      assert(cancel == null);
      cancel = subscribe(pod, controller.add);
    }

    controller = StreamController(
      onPause: pause,
      onResume: resume,
      onListen: resume,
      onCancel: pause,
      sync: true,
    );

    return controller.stream;
  }

  // Internal

  Node _ensureNode(Pod<dynamic> pod) => nodes[pod] ??= _createNode(pod);

  Node _createNode(Pod<dynamic> pod) {
    if (!pod.isKeepAlive) {
      _scheduler.runPostFrame(() => _maybeRemovePod(pod));
    }
    return Node(this, pod);
  }

  void _refresh(Pod<dynamic> pod) {
    _ensureNode(pod).invalidate();
  }

  void _maybeRemovePod(Pod<dynamic> pod) {
    final node = nodes[pod];
    if (node != null && node.canBeRemoved) {
      _removeNode(node);
    }
  }

  void _scheduleNodeRemoval(Node node) {
    _scheduler.runPostFrame(() {
      if (node.canBeRemoved) {
        _removeNode(node);
      }
    });
  }

  void _removeNode(Node node) {
    assert(node.canBeRemoved);

    var relation = node.parents;

    nodes[node.pod] = null;
    node.remove();

    while (relation != null) {
      if (relation.node.canBeRemoved) {
        _removeNode(node);
      }
      relation = relation.next;
    }
  }
}
