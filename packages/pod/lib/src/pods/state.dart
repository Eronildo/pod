part of '../pods.dart';

/// Represents an [Pod] that can be written to.
class StatePod<T> extends WritablePod<T, T> {
  /// [StatePod] constructor
  ///
  /// Requires a [initialValue].
  StatePod(this.initialValue);

  /// A [initialValue] for [StatePod].
  final T initialValue;

  @override
  T read(Ref<dynamic> ref) => initialValue;

  @override
  void write(GetPod get, SetPod set, SetSelf<T> setSelf, T value) =>
      setSelf(value);
}

/// Create a simple pod with mutable state.
///
/// ```dart
/// final counter = statePod(0);
/// ```
///
/// If you want to ensure the state is not automatically disposed when not in
/// use, then call the [Pod].keepAlive method.
///
/// ```dart
/// final counter = statePod(0).keepAlive();
/// ```
WritablePod<Value, Value> statePod<Value>(Value initialValue) =>
    StatePod(initialValue);
