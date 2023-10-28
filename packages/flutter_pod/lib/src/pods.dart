import 'package:flutter/foundation.dart';

import 'package:flutter_pod/flutter_pod.dart';

/// Create a [PodNotifier] for a [ChangeNotifier], which exposes a value
/// using the given [select] function.
PodNotifier<Pod<N>, T> changeNotifierPod<N extends ChangeNotifier, T>(
  ReaderPod<N> create,
  T Function(N notifier) select,
) =>
    internalPodNotifier<Pod<N>, T>(
      pod<N>(
        (ref) {
          final notifier = create(ref);
          ref.onDispose(notifier.dispose);
          return notifier;
        },
      ),
      (ref, parent) {
        final notifier = ref.watch(parent);

        void onChange() => ref.setSelf(select(notifier));
        notifier.addListener(onChange);
        ref.onDispose(() => notifier.removeListener(onChange));

        return select(notifier);
      },
    );

/// Create a [PodNotifier] for a [ValueNotifier], which exposes the latest
/// value.
PodNotifier<Pod<N>, T> valueNotifierPod<N extends ValueNotifier<T>, T>(
  ReaderPod<N> create,
) =>
    changeNotifierPod<N, T>(create, (n) => n.value);

/// Create a [PodNotifier] that listens to a [ValueListenable].
PodNotifier<Pod<ValueListenable<T>>, T> valueListenablePod<T>(
  ValueListenable<T> Function(Ref<ValueListenable<T>> ref) create,
) =>
    internalPodNotifier<Pod<ValueListenable<T>>, T>(
      pod<ValueListenable<T>>(create),
      (ref, pod) {
        final listenable = ref.watch(pod);

        void onChange() => ref.setSelf(listenable.value);
        listenable.addListener(onChange);
        ref.onDispose(() => listenable.removeListener(onChange));

        return listenable.value;
      },
    );
