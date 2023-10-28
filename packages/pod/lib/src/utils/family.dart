import 'dart:collection';

import 'package:pod/pod.dart';

/// Create a family factory function, for indexing similar pods with the
/// [Arg] type.
///
/// ```dart
/// final userPod =
/// familyPod((int id) => pod((ref) => ref.watch(listOfUsers).getById(id)));
///
/// // To get a pod that points to user with id 123
/// final user = container.get(userPod(123));
/// ```
T Function(Arg arg) familyPod<T extends Pod<dynamic>, Arg>(
  T Function(Arg arg) create,
) {
  final pods = HashMap<Arg, T>();
  return (arg) => pods[arg] ??= create(arg);
}

/// Alternate version of [familyPod] that holds a weak reference to each child.
T Function(Arg arg) weakFamilyPod<T extends Pod<dynamic>, Arg>(
  T Function(Arg arg) create,
) {
  final pods = HashMap<Arg, WeakReference<T>>();

  return (arg) {
    final pod = pods[arg]?.target;
    if (pod != null) {
      return pod;
    }

    final newPod = create(arg);
    pods[arg] = WeakReference(newPod);
    return newPod;
  };
}
