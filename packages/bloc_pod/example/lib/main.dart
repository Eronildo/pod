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

/// Create a counter bloc Pod
final counterBloc = blocPod<CounterBloc, int>((_) => CounterBloc());

void main() async {
  // Create a pod container.
  final container = PodContainer();

  // Print counter bloc pod's value.
  print(container.get(counterBloc)); // 0

  // Subscribe counter bloc pod's value changes.
  final cancelSubscribe = container.subscribe(counterBloc, (value) {
    print(value); // 1
  });

  // Increment the value of counter bloc.
  container.get(counterBloc.notifier).add(CounterIncrementPressed());

  /// Wait for next iteration of the event-loop
  /// to ensure event has been processed.
  await Future<void>.delayed(Duration.zero);

  // Cancel counter bloc pod's subscribe.
  cancelSubscribe();
}
