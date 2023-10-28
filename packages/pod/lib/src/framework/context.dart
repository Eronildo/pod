// ignore_for_file: prefer_asserts_with_message

part of '../framework.dart';

/// [Pod] context.
class PodContext<Value> implements Ref<Value> {
  /// [PodContext] constructor.
  PodContext(this.node) : container = node.container;

  @override
  final PodContainer container;

  /// A [Node].
  final Node node;

  Listener? _disposers;
  var _disposed = false;

  @override
  T watch<T>(Pod<T> pod) {
    final parent = container._ensureNode(pod);
    node.addParent(parent);
    return parent.value as T;
  }

  @override
  T read<T>(Pod<T> pod) => container.get(pod);

  @override
  Value? self() => node._value as Value?;

  @override
  void set<T, V>(WritablePodBase<T, V> pod, V value) {
    assert(!_disposed);
    container.set(pod, value);
  }

  @override
  void refresh(RefreshablePod pod) {
    assert(!_disposed);
    container.refresh(pod);
  }

  @override
  void refreshSelf() {
    assert(!_disposed);
    assert(node.state == NodeState.valid);
    node.invalidate();
  }

  @override
  void subscribe<T>(
    Pod<T> pod,
    void Function(T value) handler, {
    bool fireImmediately = false,
  }) {
    assert(!_disposed);
    onDispose(
      container.subscribe(
        pod,
        handler,
        fireImmediately: fireImmediately,
      ),
    );
  }

  @override
  void subscribeWithPrevious<T>(
    Pod<T> pod,
    void Function(T? previous, T value) handler, {
    bool fireImmediately = false,
  }) {
    assert(!_disposed);
    onDispose(
      container.subscribeWithPrevious(
        pod,
        handler,
        fireImmediately: fireImmediately,
      ),
    );
  }

  @override
  void mount(Pod<dynamic> pod) {
    assert(!_disposed);
    onDispose(container.mount(pod));
  }

  @override
  Stream<T> stream<T>(Pod<T> pod) => container.stream(pod);

  @override
  void setSelf(Value value) {
    assert(!_disposed);
    node.setValue(value);
  }

  @override
  void onDispose(void Function() onDispose) {
    _disposers = Listener(
      cb: onDispose,
      next: _disposers,
    );
  }

  @override
  void dispose() {
    assert(!_disposed);
    _disposed = true;

    if (_disposers == null) {
      return;
    }

    var next = _disposers;
    while (next != null) {
      next.cb();
      next = next.next;
    }
    _disposers = null;
  }
}
