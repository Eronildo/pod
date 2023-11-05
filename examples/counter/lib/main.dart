import 'package:flutter/material.dart';
import 'package:flutter_pod/flutter_pod.dart';

void main() {
  runApp(const PodScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

final counter = statePod(0);

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Text(
          '${context.watch(counter)}',
          style: const TextStyle(
            fontSize: 48,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.update(counter, (value) => ++value),
        child: const Icon(Icons.add),
      ),
    );
  }
}
