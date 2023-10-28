import 'package:pod/pod.dart';

/// Represents a function that retrieves an [Pod]'s value.
typedef GetPod = T Function<T>(Pod<T> pod);

/// Represents a function that sets a [WritablePod]'s value.
typedef SetPod = void Function<T, V>(WritablePod<T, V> pod, V value);

/// Represents function that sets the current pod's value
typedef SetSelf<T> = void Function(T value);

/// A function that creates a value from an [Ref]
typedef ReaderPod<T> = T Function(Ref<T> ref);

/// Represents the `writer` argument to [writablePod]
typedef WriterPod<T, V> = void Function(
  GetPod get,
  SetPod set,
  SetSelf<T> setSelf,
  V value,
);

/// [Override] [Pod]s.
class Override<T> {
  /// [Override] a [pod] with a [value].
  const Override(this.pod, this.value);

  /// A [Pod].
  final Pod<T> pod;

  /// A pod [value].
  final T value;
}
