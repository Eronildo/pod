# Pod

[![License: MIT][license_badge]][license_link]

**⚠️ Status: Experimental**

---

A dependency injection and state management library, fast, simple and composable.

_Inspired by [Riverpod][riverpod_link] and [Jōtai][jotai_link]_

| Package                              | Pub                                                           |
| ------------------------------------ | ------------------------------------------------------------- |
| [pod][pod_git_link]                  | [![pub package][pod_pub_badge]][pod_pub_link]                 |
| [flutter_pod][flutter_pod_git_link]  | [![pub package][flutter_pod_pub_badge]][flutter_pod_pub_link] |
| [bloc_pod][bloc_pod_git_link]        | [![pub package][bloc_pod_pub_badge]][bloc_pod_pub_link]       |

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_pod/flutter_pod.dart';

import 'package:bloc_pod/bloc_pod.dart';

/// Counter Events
sealed class CounterEvent {}
final class CounterIncrementPressed extends CounterEvent {}

/// Counter Bloc
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterIncrementPressed>((event, emit) => emit(state + 1));
  }
}

/// Create a Bloc Pod
final counterBloc = blocPod<CounterBloc, int>((_) => CounterBloc());

/// Usage of counter bloc in Widget
///
/// Requires add and import flutter_pod
class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = context.watch(counterBloc);

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text('$counter'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read(counterBloc.notifier).add(CounterIncrementPressed());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT

[pod_pub_badge]: https://img.shields.io/pub/v/pod.svg
[flutter_pod_pub_badge]: https://img.shields.io/pub/v/flutter_pod.svg
[bloc_pod_pub_badge]: https://img.shields.io/pub/v/bloc_pod.svg

[pod_pub_link]: https://pub.dev/packages/pod
[flutter_pod_pub_link]: https://pub.dev/packages/flutter_pod
[bloc_pod_pub_link]: https://pub.dev/packages/bloc_pod

[pod_git_link]: https://github.com/Eronildo/pod/tree/master/packages/pod
[flutter_pod_git_link]: https://github.com/Eronildo/pod/tree/master/packages/flutter_pod
[bloc_pod_git_link]: https://github.com/Eronildo/pod/tree/master/packages/bloc_pod

[riverpod_link]: https://riverpod.dev/
[jotai_link]: https://jotai.org/
