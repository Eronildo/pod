part of 'pod_scope.dart';

/// A [BuildContext] extension to [Pod] features.
extension PodBuildContextX on BuildContext {
  /// Read a pod once
  T read<T>(Pod<T> pod) {
    _assertContext(this);

    return PodScope._of(this)._container.get<T>(pod);
  }

  /// Watch a pod
  T watch<T>(Pod<T> pod, {VoidCallback? onDispose}) {
    _assertContext(this);

    final element = PodScope._of(this);

    element._bindingWith(
      pod,
      bindingKey: _createBindingKey(_watchPrefix, element, pod),
      element: this as Element,
      onDispose: onDispose,
    );

    return element._container.get<T>(pod);
  }

  /// Listen a pod
  void listen<T>(Pod<T> pod, void Function(T value) listener) {
    _assertContext(this);

    final element = PodScope._of(this);

    element._bindingWith(
      pod,
      bindingKey: _createBindingKey(_listenPrefix, element, pod),
      element: this as Element,
      listener: listener,
    );
  }

  /// Listen a pod with previous value
  void listenWithPrevious<T>(
    Pod<T> pod,
    void Function(T? previous, T next) listener,
  ) {
    _assertContext(this);

    final element = PodScope._of(this);

    element._bindingWith(
      pod,
      bindingKey: _createBindingKey(_previousPrefix, element, pod),
      element: this as Element,
      listenWithPreviousFn: listener,
    );
  }

  /// Watch and Listen a pod in the same time
  T consumer<T>(
    Pod<T> pod,
    void Function(T value) listener, {
    VoidCallback? onDispose,
  }) {
    _assertContext(this);

    final element = PodScope._of(this);

    element._bindingWith(
      pod,
      bindingKey: _createBindingKey(_consumerPrefix, element, pod),
      element: this as Element,
      listener: listener,
      consumer: true,
      onDispose: onDispose,
    );

    return element._container.get<T>(pod);
  }

  /// Assign a value to the pod.
  void set<T>(WritablePodBase<dynamic, T> pod, T value) {
    _assertContext(this);
    PodScope._of(this)._container.set(pod, value);
  }

  /// Update pod's value.
  void update<T, V>(WritablePodBase<T, V> pod, V Function(T value) cb) {
    _assertContext(this);
    final container = PodScope._of(this)._container;
    container.set<T, V>(pod, cb(container.get(pod)));
  }

  /// Refresh a pod.
  void refresh(RefreshablePod pod) {
    _assertContext(this);
    PodScope._of(this)._container.refresh(pod);
  }
}
