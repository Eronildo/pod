part of '../pods.dart';

/// The base class for all pods.
///
/// A pod is a special identifier,
/// that points to some state in a [PodContainer].
///
/// It also contains configuration that determines how its state is read, or
/// written (see [WritablePod]).
abstract class Pod<T> {
  /// Used by the container to read the pods value.
  T read(Ref<T> ref);

  /// Used by the container to create a read lifetime. Bit hacky, but allows us
  /// to go from dynamic to T.
  Ref<T> getContext(Node node) => PodContext(node);

  /// Check if this pod should keep alive
  ///
  /// Defaults to `false`.
  bool get isKeepAlive => _keepAlive;
  bool _keepAlive = false;

  /// Debug name for this pod
  String? get name => _name;
  String? _name;

  // void refresh(void Function(Pod pod) refresh) => refresh(this);

  /// Create an initial value override, which can be given to a PodScope or
  /// [PodContainer].
  ///
  /// By default it calls [Pod].keepAlive, to ensure the initial value is not
  /// disposed.
  Override<T> overrideWithValue(
    T value, {
    bool keepAlive = true,
  }) {
    if (keepAlive) {
      _keepAlive = true;
    }
    return Override(this, value);
  }

  @override
  String toString() => '$runtimeType(name: $_name)';
}

/// Configuration Mixin for [Pod]
///
/// Configures keep alive and name for pod.
abstract mixin class PodConfigMixin<P extends Pod<dynamic>> {
  /// Prevent the state of this pod from being automatically disposed.
  P keepAlive() {
    (this as P)._keepAlive = true;
    return this as P;
  }

  /// Set a name for debugging
  P setName(String name) {
    (this as P)._name = name;
    return this as P;
  }
}

/// [RefreshablePodMixin] that contains a [refreshable] method.
mixin RefreshablePodMixin<P extends RefreshablePod> {
  /// Create a refreshable version of this pod, which can be used with
  /// [PodContainer.refresh] or [PodContext.refresh].
  P refreshable();
}

/// [RefreshablePod] mixin that contains a [refresh] behaviour.
mixin RefreshablePod {
  /// Determines refresh behaviour.
  void refresh(void Function(Pod<dynamic> pod) refresh) => refresh(this as Pod);
}
