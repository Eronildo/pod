import 'package:flutter/material.dart';
import 'package:flutter_pod/flutter_pod.dart';

// A Counter example implemented with pod

void main() {
  runApp(
    // Adding PodScope enables Pod for the entire project
    const PodScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

/// Pods are declared globally and specify how to create a state
final counterPod = statePod(0);

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // The watch method is a utility to read and listen a pod
    final count = context.watch(counterPod);

    return Scaffold(
      appBar: AppBar(title: const Text('Counter example')),
      body: Center(
        child: Text('$count'),
      ),
      floatingActionButton: FloatingActionButton(
        // The update and set methods are utilities to change the pod's value
        onPressed: () => context.set(counterPod, 50),
        child: const Icon(Icons.add),
      ),
    );
  }
}
