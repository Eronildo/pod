import 'dart:async';
import 'dart:collection';

import 'package:pod/pod.dart';

/// An error thrown when trying to update the state of a [NotifierBase],
/// but at least one of the listeners threw.
class NotifierListenerError extends Error {
  NotifierListenerError._(
    this.errors,
    this.stackTraces,
    this.notifier,
  ) : assert(
          errors.length == stackTraces.length,
          'errors and stackTraces must match',
        );

  /// A map of all the errors and their stacktraces thrown by listeners.
  final List<Object> errors;

  /// The stacktraces associated with [errors].
  final List<StackTrace?> stackTraces;

  /// The [Notifier] that failed to update its state.
  final NotifierBase notifier;

  @override
  String toString() {
    final buffer = StringBuffer();

    for (var i = 0; i < errors.length; i++) {
      final error = errors[i];
      final stackTrace = stackTraces[i];

      buffer
        ..writeln(error)
        ..writeln(stackTrace);
    }

    return '''
At least listener of the PodNotifier $notifier threw an exception
when the notifier tried to update its state.

The exceptions thrown are:

$buffer
''';
  }
}

/// A base class for [Notifier] and [AsyncNotifier].
abstract class NotifierBase {
  late Ref<dynamic> _ref;

  /// The [Ref] from the pod associated with this notifier.
  Ref<dynamic> get ref => _ref;
}

/// A listener that can be added to a [NotifierBase] using
/// [Notifier.addListener].
///
/// This callback receives the current [Notifier.state] as a parameter.
typedef ListenerCallback<T> = void Function(T state);

/// A callback to remove a listener from notifier.
typedef RemoveListener = void Function();

final class _ListenerEntry<T> extends LinkedListEntry<_ListenerEntry<T>> {
  _ListenerEntry(this.listener);

  final ListenerCallback<T> listener;
}

/// A class which exposes a state that can change over time.
///
/// For example, [Notifier] can be used to implement a counter by doing:
///
/// ```dart
/// final counterPod = notifierPod<Counter, int>(Counter.new);
///
/// class Counter extends Notifier<int> {
///   @override
///   int build() {
///     // Inside "build", we return the initial state of the counter.
///     return 0;
///   }
///
///   void increment() {
///     state++;
///   }
/// }
/// ```
///
/// We can then listen to the counter inside widgets by doing:
///
/// ```dart
/// Text('count: ${context.watch(counterPod)}')
/// ```
///
/// And finally, we can update the counter by doing:
///
/// ```dart
/// ElevatedButton(
///   onTap: () => context.read(counterPod.notifier).increment(),
///   child: const Text('increment'),
/// )
/// ```
///
/// The state of [Notifier] is expected to be initialized synchronously.
/// For asynchronous initializations, see [AsyncNotifier].
abstract class Notifier<State> extends NotifierBase {
  late State _state;

  final _listeners = LinkedList<_ListenerEntry<State>>();

  /// Initialize a [Notifier].
  ///
  /// It is safe to use [Ref.watch] or [Ref.read] inside this method.
  ///
  /// If a dependency of this [Notifier] (when using [Ref.watch]) changes,
  /// then [build] will be re-executed. On the other hand, the [Notifier]
  /// will **not** be recreated. Its instance will be preserved between
  /// executions of [build].
  ///
  /// If this method throws, reading this [notifierPod] will rethrow the error.
  State build();

  /// The current "state" of this [Notifier].
  ///
  /// Updating this variable will synchronously call all the listeners.
  /// Notifying the listeners is O(N) with N the number of listeners.
  ///
  /// Updating the state will throw if at least one listener throws.
  State get state {
    return _state;
  }

  set state(State value) {
    _state = value;

    final errors = <Object>[];
    final stackTraces = <StackTrace?>[];
    for (final listenerEntry in _listeners) {
      try {
        listenerEntry.listener(value);
      } catch (error, stackTrace) {
        errors.add(error);
        stackTraces.add(stackTrace);
      }
    }
    if (errors.isNotEmpty) {
      throw NotifierListenerError._(errors, stackTraces, this);
    }
  }

  /// Subscribes to this object.
  ///
  /// The [listener] callback will be called whenever [state] changes.
  ///
  /// To remove this [listener], call the function returned by [addListener]
  ///
  /// ```dart
  /// final removeListener = example.addListener((value) => ...);
  /// removeListener();
  /// ```
  RemoveListener addListener(ListenerCallback<State> listener) {
    final listenerEntry = _ListenerEntry(listener);
    _listeners.add(listenerEntry);
    return () {
      if (listenerEntry.list != null) {
        listenerEntry.unlink();
      }
    };
  }
}

/// A [Notifier] implementation that is asynchronously initialized.
///
/// This is similar to a [futurePod] but allows to perform side-effects
/// by defining public methods.
///
/// It is commonly used for:
/// - Caching a network request while also allowing to perform side-effects.
///   For example, `build` could fetch information about the current "user".
///   And the [AsyncNotifier] could expose methods such as "setName",
///   to allow changing the current user name.
/// - Initializing a [Notifier] from an asynchronous source of data.
///   For example, obtaining the initial state of [Notifier] from a
///   local database.
abstract class AsyncNotifier<T> extends NotifierBase {
  late AsyncValue<T> _state;

  final _listeners = LinkedList<_ListenerEntry<AsyncValue<T>>>();

  /// Initialize an [AsyncNotifier].
  ///
  /// It is safe to use [Ref.watch] or [Ref.read] inside this method.
  ///
  /// If a dependency of this [AsyncNotifier] (when using [Ref.watch]) changes,
  /// then [build] will be re-executed. On the other hand, the [AsyncNotifier]
  /// will **not** be recreated. Its instance will be preserved between
  /// executions of [build].
  ///
  /// If this method throws or returns a future that fails, the error
  /// will be caught and an [AsyncError] will be emitted.
  FutureOr<T> build();

  /// The current "state" of this [AsyncNotifier].
  ///
  /// Updating this variable will synchronously call all the listeners.
  /// Notifying the listeners is O(N) with N the number of listeners.
  ///
  /// Updating the state will throw if at least one listener throws.
  AsyncValue<T> get state {
    return _state;
  }

  set state(AsyncValue<T> value) {
    _state = value;

    final errors = <Object>[];
    final stackTraces = <StackTrace?>[];
    for (final listenerEntry in _listeners) {
      try {
        listenerEntry.listener(value);
      } catch (error, stackTrace) {
        errors.add(error);
        stackTraces.add(stackTrace);
      }
    }
    if (errors.isNotEmpty) {
      throw NotifierListenerError._(errors, stackTraces, this);
    }
  }

  /// Subscribes to this object.
  ///
  /// The [listener] callback will be called whenever [state] changes.
  ///
  /// To remove this [listener], call the function returned by [addListener]
  ///
  /// ```dart
  /// final removeListener = example.addListener((value) => ...);
  /// removeListener();
  /// ```
  RemoveListener addListener(ListenerCallback<AsyncValue<T>> listener) {
    final listenerEntry = _ListenerEntry(listener);
    _listeners.add(listenerEntry);
    return () {
      if (listenerEntry.list != null) {
        listenerEntry.unlink();
      }
    };
  }
}

/// A pod which exposes a [Notifier] and listens to it.
///
/// This is equivalent to a [pod] that exposes ways to modify its state.
///
/// See also [Notifier] for more information.
PodNotifier<Pod<N>, T> notifierPod<N extends Notifier<T>, T>(
  N Function() create,
) {
  var isPodDisposed = false;

  final podNotifier = pod<N>((ref) {
    isPodDisposed = false;
    final notifier = create().._ref = ref;
    notifier.state = notifier.build();

    return notifier;
  });

  return internalPodNotifier<Pod<N>, T>(podNotifier, (ref, pod) {
    final notifier = ref.watch(pod);

    if (isPodDisposed) {
      notifier.state = notifier.build();
    }

    final removeListener = notifier.addListener((state) {
      ref.setSelf(state);
    });

    ref.onDispose(() {
      isPodDisposed = true;
      removeListener();
    });

    return notifier.state;
  });
}

/// A pod which creates and listen to an [AsyncNotifier].
///
/// This is similar to [futurePod] but allows to perform side-effects.
///
/// The syntax for using this pod is slightly different from the others
/// in that the pod's function doesn't receive a "ref".
/// Instead the ref are directly accessible in the associated [AsyncNotifier].
PodNotifier<Pod<N>, AsyncValue<T>>
    asyncNotifierPod<N extends AsyncNotifier<T>, T>(
  N Function() create,
) {
  var isPodDisposed = false;
  final podNotifier = pod<N>((ref) {
    final notifier = create().._ref = ref;

    var disposed = false;
    ref.onDispose(() => disposed = true);

    notifier.state = const AsyncLoading();

    final result = notifier.build();

    if (result is Future<T>) {
      result.then(
        (value) {
          if (disposed) return;
          notifier.state = AsyncValue.data(value);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (disposed) return;
          notifier.state = AsyncValue.error(error, stackTrace);
        },
      );
    } else {
      notifier.state = AsyncValue.data(result);
    }

    return notifier;
  });

  return internalPodNotifier<Pod<N>, AsyncValue<T>>(podNotifier, (ref, pod) {
    final notifier = ref.watch(pod);

    if (isPodDisposed) {
      var disposed = false;
      ref.onDispose(() => disposed = true);

      notifier.state = const AsyncLoading();

      final result = notifier.build();

      if (result is Future<T>) {
        result.then(
          (value) {
            if (disposed) return;
            notifier.state = AsyncValue.data(value);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (disposed) return;
            notifier.state = AsyncValue.error(error, stackTrace);
          },
        );
      } else {
        notifier.state = AsyncValue.data(result);
      }
    }

    final removeListener = notifier.addListener((state) {
      ref.setSelf(state);
    });

    ref.onDispose(() {
      isPodDisposed = true;
      removeListener();
    });

    return notifier.state;
  });
}

/// An extension that adds methods like [guard] to an [AsyncNotifier].
extension AsyncNotifierX<T> on AsyncNotifier<T> {
  /// Transforms a [Future] that may fail into something that is safe to read.
  ///
  /// This is useful to avoid having to do a tedious loading and `try/catch`.
  /// Instead of writing:
  ///
  /// ```dart
  /// class MyNotifier extends AsyncNotifier<MyData> {
  ///   @override
  ///   Future<MyData> build() => Future.value(MyData());
  ///
  ///   Future<void> sideEffect() async {
  ///     state = const AsyncValue.loading().copyWithPrevious(state);
  ///     try {
  ///       final response = await dio.get('my_api/data');
  ///       final data = MyData.fromJson(response);
  ///       state = AsyncValue.data(data);
  ///     } catch (err, stack) {
  ///       state = AsyncValue.error(err, stack);
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// We can use [guard] to simplify it:
  ///
  /// ```dart
  /// class MyNotifier extends AsyncNotifier<MyData> {
  ///   @override
  ///   Future<MyData> build() => Future.value(MyData());
  ///
  ///   Future<void> sideEffect() async {
  ///     // does the loading and try/catch for us like previously
  ///     await guard(() async {
  ///       final response = await dio.get('my_api/data');
  ///       return Data.fromJson(response);
  ///     });
  ///   }
  /// }
  /// ```
  Future<void> guard(Future<T> Function() future) async {
    state = AsyncValue<T>.loading().copyWithPrevious(state);
    try {
      state = AsyncValue.data(await future());
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}
