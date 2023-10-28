part of '../pods.dart';

/// Passed to the [Pod.read] method, allowing you to interact with other pods
/// and manage the lifecycle of your state.
abstract class Ref<Value> {
  /// Watch the value for the given [pod].
  T watch<T>(Pod<T> pod);

  /// Read the value for the given [pod] once.
  T read<T>(Pod<T> pod);

  /// Get the value of the current pod.
  Value? self();

  /// Set the value for the given [pod].
  void set<T, V>(WritablePod<T, V> pod, V value);

  /// Set the value for the current pod.
  void setSelf(Value value);

  /// Refresh the given [pod].
  void refresh(RefreshablePod pod);

  /// Refresh the current pod
  void refreshSelf();

  /// Subscribe to the given [pod], automatically cancelling the subscription
  /// when this pod is disposed.
  void subscribe<T>(
    Pod<T> pod,
    void Function(T value) handler, {
    bool fireImmediately = false,
  });

  /// Subscribe to the given [pod], automatically cancelling the subscription
  /// when this pod is disposed.
  void subscribeWithPrevious<T>(
    Pod<T> pod,
    void Function(T? previous, T value) handler, {
    bool fireImmediately = false,
  });

  /// Subscribe to the given [pod].
  Stream<T> stream<T>(Pod<T> pod);

  /// Unsafely access the container.
  PodContainer get container;

  /// Subscribe to the given [pod] without listening for changes.
  void mount(Pod<dynamic> pod);

  /// Register a [cb] function, that is called when the pod is invalidated or
  /// disposed.
  ///
  /// Can be called multiple times.
  void onDispose(void Function() cb);

  /// Dispose all disposers.
  void dispose() {}
}
