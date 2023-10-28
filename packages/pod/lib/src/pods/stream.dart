part of '../pods.dart';

/// See [streamPod].
abstract class PodStreamBase<P extends Pod<dynamic>, T> extends Pod<T> {
  /// A [PodStreamBase] constructor.
  PodStreamBase(this.stream, this.reader);

  /// The stream [Pod].
  final P stream;

  /// Reader callback.
  final T Function(Ref<T>, P stream) reader;

  @override
  T read(Ref<T> ref) => reader(ref, stream);
}

/// A [Pod] for [Stream]'s.
class PodStream<P extends Pod<dynamic>, T> extends PodStreamBase<P, T>
    with
        PodConfigMixin<PodStream<P, T>>,
        RefreshablePodMixin<RefreshablePodStream<P, T>> {
  /// [PodStream] constructor.
  PodStream(super.stream, super.reader);

  @override
  PodStream<P, T> keepAlive() {
    stream._keepAlive = true;
    return super.keepAlive();
  }

  @override
  PodStream<P, T> setName(String name) {
    stream._name ??= '$name.stream';
    return super.setName(name);
  }

  @override
  RefreshablePodStream<P, T> refreshable() =>
      RefreshablePodStream(stream, reader);
}

/// [RefreshablePod] for [PodStream] class.
class RefreshablePodStream<P extends Pod<dynamic>, T>
    extends PodStreamBase<P, T>
    with PodConfigMixin<RefreshablePodStream<P, T>>, RefreshablePod {
  /// [RefreshablePodStream] constructor.
  RefreshablePodStream(super.stream, super.reader);

  @override
  RefreshablePodStream<P, T> setName(String name) {
    stream._name ??= '$name.stream';
    return super.setName(name);
  }

  @override
  RefreshablePodStream<P, T> keepAlive() {
    stream._keepAlive = true;
    return super.keepAlive();
  }

  @override
  void refresh(void Function(Pod<dynamic> pod) refresh) => refresh(stream);
}
