import 'package:flutter/material.dart';
import 'package:flutter_pod/flutter_pod.dart';

void main() {
  runApp(PodScope(child: TodoApp()));
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TodoListScreen(),
    );
  }
}

class Task {
  Task(this.text, {this.isCompleted = false});
  String text;
  bool isCompleted;

  void toggle() {
    isCompleted = !isCompleted;
  }
}

final tasksPod = statePod<List<Task>>([]);
final textControllerPod = pod((_) => TextEditingController());

class TodoListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = context.watch(tasksPod);
    final textController = context.watch(textControllerPod);

    void addTask() {
      final taskText = textController.text;
      if (taskText.isNotEmpty) {
        context.update(
          tasksPod,
          (value) => [...value, Task(taskText)],
        );
        textController.clear();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'Task'),
                    onSubmitted: (_) => addTask(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addTask,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) {
                      context.set(tasksPod, [
                        for (final t in tasks)
                          if (t.text == task.text) t..toggle() else t,
                      ]);
                    },
                  ),
                  title: Text(
                    tasks[index].text,
                    style: TextStyle(
                      decoration: tasks[index].isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.set(tasksPod, [
                        for (final t in tasks)
                          if (t.text != task.text) t,
                      ]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
