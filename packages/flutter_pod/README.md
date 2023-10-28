# Pod

[![License: MIT][license_badge]][license_link]

**⚠️ Status: Experimental**

---

A dependency injection and state management library, fast, simple and composable.

_Inspired by [Riverpod][riverpod_link] and [Jōtai][jotai_link]_

| Package                              | Pub                                                           |
| ------------------------------------ | ------------------------------------------------------------- |
| [pod][pod_git_link]                  | [![pub package][pod_pub_badge]][pod_pub_link]                 |
| [flutter_pod][pod_git_link]          | [![pub package][flutter_pod_pub_badge]][flutter_pod_pub_link] |

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_pod/flutter_pod.dart';

/// A pod that asynchronously exposes the current user
final userPod = futurePod<User>((_) async {
  // fetch the user
});

class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<User> user = context.watch(userPod);

    return user.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Oops, something unexpected happened'),
      data: (user) => Text('Hello ${user.name}'),
    );
  }
}
```

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT

[pod_pub_badge]: https://img.shields.io/pub/v/pod.svg
[flutter_pod_pub_badge]: https://img.shields.io/pub/v/flutter_pod.svg

[pod_pub_link]: https://pub.dev/packages/pod
[flutter_pod_pub_link]: https://pub.dev/packages/flutter_pod

[pod_git_link]: https://github.com/Eronildo/pod/tree/master/packages/pod
[flutter_pod_git_link]: https://github.com/Eronildo/pod/tree/master/packages/flutter_pod

[riverpod_link]: https://riverpod.dev/
[jotai_link]: https://jotai.org/
