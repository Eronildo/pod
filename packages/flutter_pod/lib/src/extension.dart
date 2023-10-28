import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pod/flutter_pod.dart';

const _watch = 'watch';
const _listen = 'listen';
const _listenWithPrevious = 'listenWithPrevious';

class _CallbackWrapper<T> {
  Future<bool> Function()? willPopCallback;
}

/// A [BuildContext] extension.
extension BuildContextX on BuildContext {
  static final _listeners = HashMap<String, VoidCallback?>();

  /// Read a pod once
  T read<T>(Pod<T> pod) => PodScope.of(this, listen: false).get<T>(pod);

  /// Watch a pod
  T watch<T>(Pod<T> pod) {
    final container = PodScope.of(this);
    var value = container.get<T>(pod);

    _listeners.putIfAbsent('$_watch${pod.hashCode}$hashCode', () {
      final callbackWrapper = _CallbackWrapper<T>();
      final elementRef = WeakReference(this as Element);

      final cancelPodSubscribe = container.subscribe<T>(pod, (newValue) {
        value = newValue;
        assert(
          SchedulerBinding.instance.schedulerPhase !=
              SchedulerPhase.persistentCallbacks,
          'Trying to mutate state during a `build` method.',
        );
        if (elementRef.target?.mounted ?? false) {
          elementRef.target!.markNeedsBuild();
        }
      });

      final modalRoute = ModalRoute.of(this);

      if (modalRoute != null) {
        Future<bool> willPopCallback() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cancelPodSubscribe();
            modalRoute
                .removeScopedWillPopCallback(callbackWrapper.willPopCallback!);

            _listeners.remove('$_watch${pod.hashCode}$hashCode');
          });

          return Future.value(true);
        }

        callbackWrapper.willPopCallback = willPopCallback;
        modalRoute.addScopedWillPopCallback(callbackWrapper.willPopCallback!);
      }
      return null;
    });

    return value;
  }

  /// Listen a pod
  void listen<T>(Pod<T> pod, void Function(T value) listener) {
    final container = PodScope.of(this)..get<T>(pod);

    _listeners.putIfAbsent('$_listen${pod.hashCode}$hashCode', () {
      final callbackWrapper = _CallbackWrapper<T>();

      final cancelPodSubscribe = container.subscribe<T>(pod, (value) {
        listener(value);
      });

      final modalRoute = ModalRoute.of(this);

      if (modalRoute != null) {
        Future<bool> willPopCallback() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cancelPodSubscribe();
            modalRoute
                .removeScopedWillPopCallback(callbackWrapper.willPopCallback!);

            _listeners.remove('$_listen${pod.hashCode}$hashCode');
          });

          return Future.value(true);
        }

        callbackWrapper.willPopCallback = willPopCallback;
        modalRoute.addScopedWillPopCallback(callbackWrapper.willPopCallback!);
      }
      return null;
    });
  }

  /// Listen a pod with previous value
  void listenWithPrevious<T>(
    Pod<T> pod,
    void Function(T? previous, T next) listener,
  ) {
    final container = PodScope.of(this)..get<T>(pod);

    _listeners.putIfAbsent('$_listenWithPrevious${pod.hashCode}$hashCode', () {
      final callbackWrapper = _CallbackWrapper<T>();

      final cancelPodSubscribe =
          container.subscribeWithPrevious<T>(pod, (previous, next) {
        listener(previous, next);
      });

      final modalRoute = ModalRoute.of(this);

      if (modalRoute != null) {
        Future<bool> willPopCallback() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cancelPodSubscribe();
            modalRoute
                .removeScopedWillPopCallback(callbackWrapper.willPopCallback!);

            _listeners.remove('$_listenWithPrevious${pod.hashCode}$hashCode');
          });

          return Future.value(true);
        }

        callbackWrapper.willPopCallback = willPopCallback;
        modalRoute.addScopedWillPopCallback(callbackWrapper.willPopCallback!);
      }
      return null;
    });
  }

  /// Assign a value to the pod.
  void set<T>(WritablePodBase<dynamic, T> pod, T value) {
    PodScope.of(this, listen: false).set(pod, value);
  }

  /// Update the pod value.
  void update<T, V>(WritablePodBase<T, V> pod, V Function(T value) cb) {
    final container = PodScope.of(this, listen: false);
    container.set<T, V>(pod, cb(container.get(pod)));
  }

  /// Refresh a pod.
  void refresh(RefreshablePod pod) =>
      PodScope.of(this, listen: false).refresh(pod);
}
