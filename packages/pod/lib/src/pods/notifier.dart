part of '../pods.dart';

/// [PodNotifier] base class.
abstract class PodNotifierBase<N extends Pod<dynamic>, T> extends Pod<T> {
  /// [PodNotifierBase] constructor..
  PodNotifierBase(this.notifier, this.reader);

  /// The notifier [Pod].
  final N notifier;

  /// Reader callback.
  final T Function(Ref<T>, N notifier) reader;

  @override
  T read(Ref<T> ref) => reader(ref, notifier);
}

/// A Notifier [Pod].
class PodNotifier<N extends Pod<dynamic>, T> extends PodNotifierBase<N, T>
    with
        PodConfigMixin<PodNotifier<N, T>>,
        RefreshablePodMixin<RefreshablePodNotifier<N, T>> {
  /// [PodNotifierBase] constructor
  ///
  /// Requires a [notifier] and a [reader] callback.
  PodNotifier(super.notifier, super.reader);

  @override
  PodNotifier<N, T> keepAlive() {
    notifier._keepAlive = true;
    return super.keepAlive();
  }

  @override
  PodNotifier<N, T> setName(String name) {
    notifier._name ??= '$name.notifier';
    return super.setName(name);
  }

  @override
  RefreshablePodNotifier<N, T> refreshable() =>
      RefreshablePodNotifier(notifier, reader);
}

/// [RefreshablePod] for [PodNotifier].
class RefreshablePodNotifier<N extends Pod<dynamic>, T>
    extends PodNotifierBase<N, T>
    with PodConfigMixin<RefreshablePodNotifier<N, T>>, RefreshablePod {
  /// [RefreshablePodNotifier] constructor.
  RefreshablePodNotifier(super.notifier, super.reader);

  @override
  RefreshablePodNotifier<N, T> setName(String name) {
    notifier._name ??= '$name.notifier';
    return super.setName(name);
  }

  @override
  RefreshablePodNotifier<N, T> keepAlive() {
    notifier._keepAlive = true;
    return super.keepAlive();
  }

  @override
  void refresh(void Function(Pod<dynamic> pod) refresh) => refresh(notifier);
}

/// Create a [Pod] that is linked to a notifier [Pod].
///
/// Can be used to tie a state to the thing that generates it.
///
/// I.e the notifier could be a [ValueNotifier<T>] and the child would be the
/// value it emits, of type `T`. It would be represented by
/// [PodNotifier<Pod<ValueNotifier<T>>, T>].
PodNotifier<N, T> internalPodNotifier<N extends Pod<dynamic>, T>(
  N notifier,
  T Function(Ref<T> ref, N notifier) create,
) =>
    PodNotifier(notifier, create);
