import 'package:bloc/bloc.dart';
import 'package:pod/pod.dart';

/// Create a [PodNotifier] for a [Bloc], which exposes the latest state.
PodNotifier<Pod<B>, T> blocPod<B extends BlocBase<T>, T>(
  ReaderPod<B> create,
) =>
    internalPodNotifier<Pod<B>, T>(
      pod<B>(
        (ref) {
          final bloc = create(ref);
          ref.onDispose(bloc.close);
          return bloc;
        },
      ),
      (ref, pod) {
        final bloc = ref.watch(pod);

        final streamSubscription =
            bloc.stream.listen((event) => ref.setSelf(event));
        ref.onDispose(streamSubscription.cancel);

        return bloc.state;
      },
    );
