// ignore_for_file: prefer_asserts_with_message

part of '../framework.dart';

/// [Node] state.
enum NodeState {
  /// A uninitialized [Node].
  uninitialized(waitingForValue: true),

  /// A stale [Node].
  stale(initialized: true, waitingForValue: true),

  /// A valid [Node].
  valid(initialized: true),

  /// A removed [Node].
  removed(alive: false);

  const NodeState({
    this.waitingForValue = false,
    this.alive = true,
    this.initialized = false,
  });

  /// Check if [Node] is waiting for initial value.
  final bool waitingForValue;

  /// Check if [Node] is alive.
  final bool alive;

  /// Check if [Node] is initialized.
  final bool initialized;
}

/// A [Pod] controller.
class Node {
  /// [Node] constructor
  ///
  /// Requires a [container] and a [pod].
  Node(this.container, this.pod);

  /// See [PodContainer].
  final PodContainer container;

  /// A [Pod] binded to this [Node].
  final Pod<dynamic> pod;

  /// The [Node] state.
  NodeState state = NodeState.uninitialized;

  /// The parents.
  Relation? parents;

  /// The previous parents.
  Relation? previousParents;

  /// The children.
  Relation? children;

  /// The [Listener]'s.
  Listener? listeners;

  Ref<dynamic>? _ref;

  /// Check if this [Node] can be removed.
  bool get canBeRemoved =>
      !pod.isKeepAlive &&
      listeners == null &&
      children == null &&
      state != NodeState.removed;

  dynamic _value;

  /// [Node] value.
  dynamic get value {
    assert(state.alive);

    if (state.waitingForValue) {
      _ref = pod.getContext(this);

      if (_ref != null) {
        final value = pod.read(_ref!);
        if (state.waitingForValue) {
          setValue(value);
        }
      }

      // Removed orphaned parents
      if (previousParents != null) {
        var relation = previousParents;
        previousParents = null;
        while (relation != null) {
          relation.node.removeChild(this);
          if (relation.node.canBeRemoved) {
            container._scheduleNodeRemoval(relation.node);
          }

          relation = relation.next;
        }
      }
    }

    return _value;
  }

  /// Add a parent [Node].
  void addParent(Node node) {
    assert(state.alive);

    parents = Relation(
      node: node,
      next: parents,
    );

    if (previousParents != null) {
      if (previousParents?.node == node) {
        previousParents = previousParents?.next;
      } else {
        previousParents?.remove(node);
      }
    }

    // Add to parent children
    if (node.children?.contains(this) != true) {
      node.children = Relation(
        node: this,
        next: node.children,
      );
    }
  }

  /// Remove a child [Node].
  void removeChild(Node node) {
    if (children?.node == node) {
      children = children?.next;
      children?.previous = null;
    } else {
      children?.remove(node);
    }
  }

  /// Set [Node]'s value.
  void setValue(dynamic value) {
    assert(state.alive);

    if (state == NodeState.uninitialized) {
      state = NodeState.valid;
      _value = value;
      return;
    }

    state = NodeState.valid;
    if (value == _value) {
      return;
    }

    _value = value;

    invalidateChildren();
    notifyListeners();
  }

  /// Invalidate this [Node].
  void invalidate() {
    assert(state.alive);

    if (state == NodeState.valid) {
      state = NodeState.stale;
      disposeContext();
    }

    // Rebuild
    value;
  }

  /// Invalidate children.
  void invalidateChildren() {
    assert(state == NodeState.valid);

    if (children == null) {
      return;
    }

    var relation = children;
    children = null;

    while (relation != null) {
      relation.node.invalidate();
      relation = relation.next;
    }
  }

  /// Notify the Listeners
  void notifyListeners() {
    assert(state.initialized, state.toString());

    if (listeners == null) {
      return;
    }

    var next = listeners;
    while (next != null) {
      next.cb();
      next = next.next;
    }
  }

  /// Dispose the [Ref] context.
  void disposeContext() {
    if (_ref != null) {
      _ref?.dispose();
      _ref = null;
    }

    previousParents = parents;
    parents = null;
  }

  /// Remove this [Node].
  void remove() {
    assert(canBeRemoved);

    state = NodeState.removed;

    if (_ref == null) {
      return;
    }

    disposeContext();

    if (previousParents == null) {
      return;
    }

    var relation = previousParents;
    previousParents = null;
    while (relation != null) {
      relation.node.removeChild(this);
      if (relation.node.canBeRemoved) {
        container._removeNode(relation.node);
      }

      relation = relation.next;
    }
  }

  /// Add listener callbacks to the [Node].
  void Function() addListener(void Function() handler) {
    final l = Listener(
      cb: handler,
      next: listeners,
    );
    listeners = l;

    return () {
      if (listeners == l) {
        listeners = l.next;
        l.next?.previous = null;
      } else {
        l.previous?.next = l.next;
        l.next?.previous = l.previous;
      }
    };
  }

  @override
  String toString() => 'Node(pod: $pod, _state: $state, '
      'canBeRemoved: $canBeRemoved, value: $value)';
}

/// [Relation] class to connect [Node]s.
class Relation {
  /// [Relation] constructor.
  Relation({
    required this.node,
    this.next,
  }) {
    next?.previous = this;
  }

  /// A [Node].
  final Node node;

  /// Previous [Relation].
  Relation? previous;

  /// Next [Relation].
  Relation? next;

  /// Check if contains a [Node] in this relation or in your nexts.
  bool contains(Node node) {
    Relation? relation = this;
    while (relation != null) {
      if (relation.node == node) {
        return true;
      }
      relation = relation.next;
    }
    return false;
  }

  /// Remove a [Node].
  void remove(Node node) {
    Relation? relation = this;
    while (relation != null) {
      if (relation.node == node) {
        relation.previous?.next = relation.next;
        relation.next?.previous = relation.previous;
      }

      relation = relation.next;
    }
  }
}

/// Listener class for [Node]s.
class Listener {
  /// [Listener] constructor.
  Listener({
    required this.cb,
    this.next,
  }) {
    next?.previous = this;
  }

  /// Callback listener function.
  final void Function() cb;

  /// Previous [Listener].
  Listener? previous;

  /// Next [Listener].
  Listener? next;
}
