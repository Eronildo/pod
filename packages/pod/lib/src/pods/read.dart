part of '../pods.dart';

/// See [pod].
abstract class ReadPodBase<Value> extends Pod<Value> {
  /// Create a ReaderPod by reader.
  ReadPodBase(this.reader);

  /// ReaderPod reader.
  final ReaderPod<Value> reader;

  @override
  Value read(Ref<Value> ref) => reader(ref);
}

/// See [pod].
class ReadPod<T> extends ReadPodBase<T>
    with
        PodConfigMixin<ReadPod<T>>,
        RefreshablePodMixin<RefreshableReadPod<T>> {
  /// Create a [ReadPod].
  ReadPod(super.reader);

  @override
  RefreshableReadPod<T> refreshable() => RefreshableReadPod(reader);
}

/// See [pod].
class RefreshableReadPod<T> = ReadPodBase<T>
    with PodConfigMixin<RefreshableReadPod<T>>, RefreshablePod;

/// Create a read only pod that can interact with other pod's to create
/// derived state.
///
/// ```dart
/// final count = statePod(0);
/// final countTimesTwo = pod((ref) => ref.watch(count) * 2);
/// ```
ReadPod<Value> pod<Value>(ReaderPod<Value> create) => ReadPod(create);
