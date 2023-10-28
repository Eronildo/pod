import 'package:flutter/widgets.dart';

import 'package:flutter_pod/flutter_pod.dart';

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
class PodScope extends StatefulWidget {
  /// [PodScope] constructor.
  const PodScope({
    required this.child,
    super.key,
    this.overrides = const [],
  });

  /// Information on how to override a pod.
  final List<Override<dynamic>> overrides;

  /// The part of the widget tree that can use Pod and has overridden pods.
  final Widget child;

  /// Read the current [PodContainer] for a [BuildContext].
  static PodContainer of(
    BuildContext context, {
    bool listen = true,
  }) {
    UncontrolledPodScope? scope;

    scope = listen
        ? context //
            .dependOnInheritedWidgetOfExactType<UncontrolledPodScope>()
        : (context
            .getElementForInheritedWidgetOfExactType<UncontrolledPodScope>()
            ?.widget as UncontrolledPodScope?);

    if (scope == null) {
      throw StateError('No PodScope found');
    }

    return scope.container;
  }

  @override
  PodScopeState createState() => PodScopeState();
}

/// Do not use: The [State] of [PodScope].
class PodScopeState extends State<PodScope> {
  /// The [PodContainer] exposed to [PodScope.child].
  @visibleForTesting
  late final PodContainer container;
  var _dirty = false;

  @override
  void initState() {
    super.initState();

    container = PodContainer(
      overrides: widget.overrides,
    );
  }

  @override
  void didUpdateWidget(PodScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _dirty = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_dirty) {
      _dirty = false;
    }

    return UncontrolledPodScope(
      container: container,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Expose a [PodContainer] to the widget tree.
class UncontrolledPodScope extends InheritedWidget {
  /// [UncontrolledPodScope] constructor.
  const UncontrolledPodScope({
    required this.container,
    required super.child,
    super.key,
  });

  /// The [PodContainer] exposed to the widget tree.
  final PodContainer container;

  @override
  bool updateShouldNotify(UncontrolledPodScope oldWidget) {
    return container != oldWidget.container;
  }
}
