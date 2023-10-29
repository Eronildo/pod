import 'package:pod/pod.dart';

void main() {
  // Create a state pod.
  final counterPod = statePod(1);

  // Create a derived Pod.
  final counterTimesTwoPod = pod((ref) => ref.watch(counterPod) * 2);

  // Create a pod container.
  final container = PodContainer();

  // Print derived pod's value.
  print(container.get(counterTimesTwoPod)); // 2

  // Subscribe derived pod's value changes.
  final cancelSubscribe = container.subscribe(counterTimesTwoPod, (value) {
    print(value); // 4
  });

  // Set the value of counter pod to 2.
  container.set(counterPod, 2);

  // Cancel derived pod's subscribe.
  cancelSubscribe();
}
