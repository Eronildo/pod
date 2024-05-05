part of 'pod_scope.dart';

const _assertContextMessage =
    'This must be called with the context of a Widget.';

const _watchPrefix = 'watch';
const _listenPrefix = 'listen';
const _previousPrefix = 'previous';
const _consumerPrefix = 'consumer';

void _assertContext(BuildContext context) {
  assert(
    context is Element,
    _assertContextMessage,
  );
}

String _createBindingKey<T>(
  String prefix,
  Element element,
  Pod<T> pod,
) =>
    '$prefix:${element.hashCode}${pod.hashCode}';

/// A [Pod] features extension.
extension GetPodX<T> on Pod<T> {
  /// Read a pod once
  T of(BuildContext context) {
    _assertContext(context);

    return PodScope._of(context)._container.get<T>(this);
  }

  /// Read a pod once
  T call(BuildContext context) => of(context);

  /// Watch a pod
  T watch(BuildContext context, {VoidCallback? onDispose}) {
    _assertContext(context);

    final element = PodScope._of(context);

    element._bindingWith(
      this,
      bindingKey: _createBindingKey<T>(_watchPrefix, element, this),
      element: context as Element,
      onDispose: onDispose,
    );

    return element._container.get<T>(this);
  }

  /// Listen a pod
  void listen(BuildContext context, void Function(T value) listener) {
    _assertContext(context);

    final element = PodScope._of(context);
    element._bindingWith(
      this,
      bindingKey: _createBindingKey<T>(_listenPrefix, element, this),
      element: context as Element,
      listener: listener,
    );
  }

  /// Listen a pod with previous value
  void listenWithPrevious(
    BuildContext context,
    void Function(T? previous, T next) listener,
  ) {
    _assertContext(context);

    final element = PodScope._of(context);

    element._bindingWith(
      this,
      bindingKey: _createBindingKey<T>(_previousPrefix, element, this),
      element: context as Element,
      listenWithPreviousFn: listener,
    );
  }

  /// Watch and Listen a pod in the same time
  T consumer(
    BuildContext context,
    void Function(T value) listener, {
    VoidCallback? onDispose,
  }) {
    _assertContext(context);

    final element = PodScope._of(context);

    element._bindingWith(
      this,
      bindingKey: _createBindingKey<T>(_consumerPrefix, element, this),
      element: context as Element,
      listener: listener,
      consumer: true,
      onDispose: onDispose,
    );

    return element._container.get<T>(this);
  }
}

/// A [WritablePod] features extension.
extension WritablePodBaseX<T, V> on WritablePodBase<T, V> {
  /// Assign a value to the pod.
  void set(BuildContext context, T value) {
    _assertContext(context);
    PodScope._of(context)._container.set(this, value);
  }

  /// Update pod's value.
  void update(BuildContext context, V Function(T value) cb) {
    _assertContext(context);
    final container = PodScope._of(context)._container;
    container.set<T, V>(this, cb(container.get(this)));
  }
}

/// A [RefreshablePod] features extension.
extension RefreshablePodX on RefreshablePod {
  /// Refresh a pod.
  void selfRefresh(BuildContext context) {
    _assertContext(context);
    PodScope._of(context)._container.refresh(this);
  }
}

/// A Listenable [PodNotifier] features extension.
extension PodListenableX<N extends Listenable, T> on PodNotifier<Pod<N>, T> {
  /// Read a pod once
  N of(BuildContext context) {
    _assertContext(context);

    return PodScope._of(context)._container.get<N>(notifier);
  }

  /// Read a pod once
  N call(BuildContext context) => of(context);
}

/// A [PodNotifier] features extension.
extension PodNotifierX<N extends NotifierBase, T> on PodNotifier<Pod<N>, T> {
  /// Read a pod once
  N of(BuildContext context) {
    _assertContext(context);

    return PodScope._of(context)._container.get<N>(notifier);
  }

  /// Read a pod once
  N call(BuildContext context) => of(context);
}
