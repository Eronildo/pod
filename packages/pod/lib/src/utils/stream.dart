import 'package:pod/pod.dart';

/// Represents a [PodStream] for a streaming operation.
typedef StreamPod<T> = PodStream<Pod<Stream<T>>, AsyncValue<T>>;

/// Create a Pod of a [Stream].
StreamPod<T> streamPod<T>(
  ReaderPod<Stream<T>> create,
) =>
    PodStream(
      pod((ref) => create(ref).asBroadcastStream()),
      (ref, stream) {
        T? currentData;

        final subscription = ref.watch(stream).listen(
              (data) {
                currentData = data;
                if (ref.self() != null) {
                  ref.setSelf(
                    AsyncValue<T>.loading().copyWithPrevious(ref.self()!),
                  );
                } else {
                  ref.setSelf(AsyncValue<T>.loading());
                }
              },
              onError: (Object err, StackTrace stackTrace) => ref.setSelf(
                AsyncValue.error(
                  err,
                  stackTrace,
                ),
              ),
              onDone: () {
                if (currentData != null) {
                  // ignore: null_check_on_nullable_type_parameter
                  ref.setSelf(AsyncValue.data(currentData!));
                  currentData = null;
                }
              },
            );

        ref.onDispose(subscription.cancel);

        final previous = ref.self();
        final loading = AsyncValue<T>.loading();

        if (previous == null) {
          return loading;
        }

        return loading.copyWithPrevious(ref.self()!);
      },
    );
