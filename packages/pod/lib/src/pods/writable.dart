part of '../pods.dart';

/// Represents an [Pod] that can be written to.
abstract class WritablePodBase<T, V> extends Pod<T> {
  /// When the pod receives a write with the given [value], this method
  /// determines the outcome.
  void write(GetPod get, SetPod set, SetSelf<T> setSelf, V value);
}

/// Represents an [Pod] that can be written to.
abstract class WritablePod<T, V> extends WritablePodBase<T, V>
    with
        PodConfigMixin<WritablePod<T, V>>,
        RefreshablePodMixin<RefreshableWritablePod<T, V>> {
  @override
  RefreshableWritablePod<T, V> refreshable() => RefreshableWritablePod(this);
}

/// Create a Refreshable WritablePod.
class RefreshableWritablePod<T, V> extends WritablePodBase<T, V>
    with PodConfigMixin<RefreshableWritablePod<T, V>>, RefreshablePod {
  /// [RefreshableWritablePod] constructor.
  RefreshableWritablePod(this._parent);

  final WritablePod<T, V> _parent;

  @override
  T read(Ref<T> ref) => _parent.read(ref);

  @override
  void write(GetPod get, SetPod set, SetSelf<T> setSelf, V value) =>
      _parent.write(get, set, setSelf, value);
}

class _WritablePodImpl<T, V> extends WritablePod<T, V> {
  _WritablePodImpl(this.reader, this.writer);

  final ReaderPod<T> reader;
  final WriterPod<T, V> writer;

  @override
  T read(Ref<T> ref) => reader(ref);

  @override
  void write(GetPod get, SetPod set, SetSelf<T> setSelf, V value) =>
      writer(get, set, setSelf, value);
}

/// Creates an [WritablePod] that can be used to implement custom write logic.
WritablePod<T, V> writablePod<T, V>(
  ReaderPod<T> reader,
  WriterPod<T, V> writer,
) =>
    _WritablePodImpl(reader, writer);
