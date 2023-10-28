import 'package:pod/pod.dart';

/// Represents a [PodFuture] for an async operation.
typedef FuturePod<T> = PodFuture<Pod<Future<T>>, AsyncValue<T>>;

/// Create a [PodFuture] that returns a [AsyncValue] representing the
/// current state of the [Future]'s execution.
///
/// The `future` property is set to the [Future] itself, so you can `await` it
/// if required.
FuturePod<T> futurePod<T>(
  ReaderPod<Future<T>> create,
) =>
    PodFuture(
      pod(create),
      (ref, pod) {
        var disposed = false;
        ref.onDispose(() => disposed = true);

        ref.watch(pod).then(
          (value) {
            if (disposed) return;
            ref.setSelf(AsyncValue<T>.data(value));
          },
          onError: (Object error, StackTrace stackTrace) {
            if (disposed) return;
            ref.setSelf(AsyncValue<T>.error(error, stackTrace));
          },
        );

        final previous = ref.self();
        final loading = AsyncValue<T>.loading();

        if (previous == null) {
          return loading;
        }

        return loading.copyWithPrevious(ref.self()!);
      },
    );
