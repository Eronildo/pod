import 'package:pod/pod.dart';

/// [Pod] extension.
extension PodExtension<T> on Pod<T> {
  /// Create a derived pod, that transforms a pod's value using the given
  /// function [cb].
  ///
  /// Only rebuilds when the selected value changes.
  PodNotifier<Pod<T>, B> select<B>(B Function(T value) cb) => PodNotifier(
        this,
        (ref, parent) => cb(
          ref.watch(parent),
        ),
      );

  /// Create a derived pod, that filters the values using the given predicate.
  PodFuture<Pod<T>, AsyncValue<T>> filter(
    bool Function(T value) predicate,
  ) =>
      PodFuture(
        this,
        (ref, parent) {
          ref.subscribe(
            parent,
            (T val) {
              if (predicate(val)) {
                ref.setSelf(AsyncValue.data(val));
              }
            },
            fireImmediately: true,
          );

          return ref.self() ?? const AsyncValue.loading();
        },
      );
}

/// [AsyncValue] extension.
extension AsyncValuePodExtension<T> on Pod<AsyncValue<T>> {
  /// Create a derived pod, that transforms a pod's value using the given
  /// function [cb].
  ///
  /// Only rebuilds when the selected value changes.
  PodFuture<Pod<AsyncValue<T>>, V> rawSelect<V>(
    V Function(AsyncValue<T> value) cb,
  ) =>
      PodFuture(this, (ref, parent) => cb(ref.watch(parent)));

  /// Create a derived pod, that transforms a pod's value using the given
  /// function [cb].
  ///
  /// Only rebuilds when the selected value changes.
  PodFuture<Pod<AsyncValue<T>>, AsyncValue<V>> select<V>(
    V Function(T value) cb,
  ) =>
      PodFuture(
        this,
        (ref, parent) {
          final value = ref.watch(parent).transform(cb);
          if (value.valueOrNull != null) {
            // ignore: null_check_on_nullable_type_parameter
            return AsyncValue.data(value.valueOrNull!);
          }

          final prev = ref.self();
          if (prev is AsyncValue<V>) {
            return prev;
          }

          return value;
        },
      );

  /// Create a derived pod, that transforms a pod's value using the given
  /// function [cb].
  ///
  /// Only rebuilds when the selected value changes.
  PodFuture<Pod<AsyncValue<T>>, Future<V>> asyncSelect<V>(
    V Function(T value) cb,
  ) =>
      select(cb).rawSelect(
        (val) => val.maybeWhen(
          data: Future.value,
          orElse: () => Future.any([]),
        ),
      );
}

/// [PodFuture] extension.
extension PodFutureExtension<V, P extends Pod<dynamic>>
    on PodFuture<P, AsyncValue<V>> {
  /// Create a derived pod, that transforms a pod's value using the given
  /// function [cb].
  ///
  /// Only rebuilds when the selected value changes.
  PodFuture<P, T> rawSelect<T>(
    T Function(AsyncValue<V> value) cb,
  ) =>
      PodFuture(
        future,
        (ref, future) => cb(
          ref.watch(this),
        ),
      );

  /// Create a derived pod, that transforms a pod's value using the given
  /// function [cb].
  ///
  /// Only rebuilds when the selected value changes.
  PodFuture<P, AsyncValue<T>> select<T>(
    T Function(V value) cb,
  ) =>
      PodFuture(
        future,
        (ref, future) {
          final value = ref.watch(this).transform(cb);
          if (value.valueOrNull != null) {
            // ignore: null_check_on_nullable_type_parameter
            return AsyncValue.data(value.valueOrNull!);
          }

          final prev = ref.self();
          if (prev is AsyncValue<T>) {
            return prev;
          }

          return value;
        },
      );

  /// Create a derived pod, that transforms a pod's value using the given
  /// function [cb].
  ///
  /// Only rebuilds when the selected value changes.
  PodFuture<P, Future<T>> asyncSelect<T>(
    T Function(V value) cb,
  ) =>
      select(cb).rawSelect(
        (val) => val.maybeWhen(
          data: Future.value,
          orElse: () => Future.any([]),
        ),
      );
}
