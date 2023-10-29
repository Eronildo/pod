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
import 'package:pod/pod.dart';

void main() {
  // Create a state pod.
  final counterPod = statePod(0);

  // Create a derived Pod.
  final counterTimesTwoPod = pod((ref) => ref.watch(counterPod) * 2);

  // Create a pod container.
  final container = PodContainer();

  // Print derived pod's value.
  print(container.get(counterTimesTwoPod)); // 0

  // Subscribe derived pod's value changes.
  final cancelSubscribe = container.subscribe(counterTimesTwoPod, (value) {
    print(value); // 4
  });

  // Set the value of counter pod to 2.
  container.set(counterPod, 2);

  // Cancel derived pod's subscribe.
  cancelSubscribe();
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
