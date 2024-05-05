import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pod/flutter_pod.dart';

part 'pod_extension.dart';
part 'context_extension.dart';

/// A widget that stores the state of pods.
///
/// All Flutter applications using Pod must contain a [PodScope] at
/// the root of their widget tree. It is done as followed:
///
/// ```dart
/// void main() {
///   runApp(
///     // Enabled Pod for the entire application
///     PodScope(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class PodScope extends InheritedWidget {
  /// [PodScope] constructor.
  const PodScope({
    required super.child,
    super.key,
    this.overrides = const [],
  });

  /// Information on how to override a pod.
  final List<Override<dynamic>> overrides;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  @override
  InheritedElement createElement() => _PodScopeElement(this);

  static _PodScopeElement _of(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<PodScope>();

    assert(
      element != null,
      '''

  Wrap your app with `PodScope` in runApp:

  runApp(
    const PodScope( // <--
      child: MyApp(),
    ),
  );

  ''',
    );

    final podScopeElement = element! as _PodScopeElement;

    return podScopeElement;
  }
}

class _PodScopeElement extends InheritedElement {
  _PodScopeElement(super.widget);

  bool _dirty = false;
  PodScope get _scope => widget as PodScope;

  late final PodContainer _container = PodContainer(
    overrides: _scope.overrides,
  );

  late final _elementBindings = <Element, Set<_BindingModel>>{};

  VoidCallback _subscribePod<T>({
    required Pod<T> pod,
    void Function(T value)? listener,
    void Function(T? previous, T next)? listenWithPreviousFn,
    bool consumer = false,
  }) {
    late VoidCallback subscribePodFn;
    if (listenWithPreviousFn != null) {
      subscribePodFn = _container.subscribeWithPrevious<T>(
        pod,
        (previous, value) {
          listenWithPreviousFn(previous, value);
        },
        fireImmediately: true,
      );
    } else {
      subscribePodFn = _container.subscribe<T>(pod, (value) {
        if (listener != null) {
          listener(value);
          if (!consumer) {
            return;
          }
        }
        _rebuild();
      });
    }

    return subscribePodFn;
  }

  _BindingModel _createBindingModel({
    required String bindingKey,
    required Element element,
    required VoidCallback subscribePodFn,
    VoidCallback? onDispose,
  }) {
    element.dependOnInheritedElement(this);
    return _BindingModel(
      bindingKey: bindingKey,
      subscribeFn: () {
        subscribePodFn();
        onDispose?.call();
      },
    );
  }

  _BindingModel _subscribePodAndReturnBindingModel<T>({
    required Pod<T> pod,
    required Element element,
    required String bindingKey,
    VoidCallback? onDispose,
    void Function(T value)? listener,
    void Function(T? previous, T next)? listenWithPreviousFn,
    bool consumer = false,
  }) {
    final subscribePodFn = _subscribePod(
      pod: pod,
      listener: listener,
      listenWithPreviousFn: listenWithPreviousFn,
      consumer: consumer,
    );
    return _createBindingModel(
      bindingKey: bindingKey,
      element: element,
      subscribePodFn: subscribePodFn,
      onDispose: onDispose,
    );
  }

  void _bindingWith<T>(
    Pod<T> pod, {
    required Element element,
    required String bindingKey,
    VoidCallback? onDispose,
    void Function(T value)? listener,
    void Function(T? previous, T next)? listenWithPreviousFn,
    bool consumer = false,
  }) {
    final binding = _elementBindings[element];

    if (binding == null) {
      _elementBindings[element] = {
        _subscribePodAndReturnBindingModel(
          pod: pod,
          bindingKey: bindingKey,
          element: element,
          listener: listener,
          listenWithPreviousFn: listenWithPreviousFn,
          consumer: consumer,
          onDispose: onDispose,
        ),
      };
      return;
    }

    final existing = binding.singleWhere(
      (b) => b._bindingKey == bindingKey,
      orElse: _BindingModel._empty,
    );

    if (existing._bindingKey == '') {
      final bindingModel = _subscribePodAndReturnBindingModel(
        pod: pod,
        bindingKey: bindingKey,
        element: element,
        listener: listener,
        listenWithPreviousFn: listenWithPreviousFn,
        consumer: consumer,
        onDispose: onDispose,
      );
      binding.add(bindingModel);
    }
  }

  Future<void> _rebuild() async {
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      await SchedulerBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    _dirty = true;
    markNeedsBuild();
  }

  @override
  Widget build() {
    if (_dirty) {
      notifyClients(widget as PodScope);
    }
    return super.build();
  }

  @override
  void notifyClients(InheritedWidget oldWidget) {
    super.notifyClients(oldWidget);
    _dirty = false;
  }

  @override
  void removeDependent(Element dependent) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (dependent.mounted) return;
      final subscribes = _elementBindings.remove(dependent);

      if (subscribes == null) return;

      for (final subscribe in subscribes) {
        subscribe._subscribeFn();
      }
    });

    super.removeDependent(dependent);
  }
}

class _BindingModel {
  _BindingModel({
    required String bindingKey,
    required VoidCallback subscribeFn,
  })  : _subscribeFn = subscribeFn,
        _bindingKey = bindingKey;

  factory _BindingModel._empty() => _BindingModel(
        bindingKey: '',
        subscribeFn: () {},
      );

  final String _bindingKey;
  final VoidCallback _subscribeFn;
}
