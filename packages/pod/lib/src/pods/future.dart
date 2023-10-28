part of '../pods.dart';

/// See [futurePod].
abstract class PodFutureBase<F extends Pod<dynamic>, T> extends Pod<T> {
  /// [PodFutureBase] constructor.
  PodFutureBase(this.future, this.reader);

  /// The future [Pod].
  final F future;

  /// Reader callback.
  final T Function(Ref<T>, F future) reader;

  @override
  T read(Ref<T> ref) => reader(ref, future);
}

/// See [futurePod].
class PodFuture<F extends Pod<dynamic>, T> extends PodFutureBase<F, T>
    with
        PodConfigMixin<PodFuture<F, T>>,
        RefreshablePodMixin<RefreshablePodFuture<F, T>> {
  /// [PodFuture] constructor.
  PodFuture(super.future, super.reader);

  @override
  PodFuture<F, T> keepAlive() {
    future._keepAlive = true;
    return super.keepAlive();
  }

  @override
  PodFuture<F, T> setName(String name) {
    future._name ??= '$name.future';
    return super.setName(name);
  }

  @override
  RefreshablePodFuture<F, T> refreshable() =>
      RefreshablePodFuture(future, reader);
}

/// [RefreshablePod] for [Future]'s.
class RefreshablePodFuture<F extends Pod<dynamic>, T>
    extends PodFutureBase<F, T>
    with PodConfigMixin<RefreshablePodFuture<F, T>>, RefreshablePod {
  /// [RefreshablePodFuture] constructor
  ///
  /// Requires a [future] and a [reader] callback.
  RefreshablePodFuture(super.future, super.reader);

  @override
  RefreshablePodFuture<F, T> setName(String name) {
    future._name ??= '$name.future';
    return super.setName(name);
  }

  @override
  RefreshablePodFuture<F, T> keepAlive() {
    future._keepAlive = true;
    return super.keepAlive();
  }

  @override
  void refresh(void Function(Pod<dynamic> pod) refresh) => refresh(future);
}
