import 'package:flutter/material.dart';
import 'package:flutter_pod/flutter_pod.dart';
import 'package:hook_it/hook_it.dart';

import 'todo.dart';

/// Some keys used for testing
final addTodoKey = UniqueKey();
final activeFilterKey = UniqueKey();
final completedFilterKey = UniqueKey();
final allFilterKey = UniqueKey();

/// Creates a [TodoList] and initialize it with pre-defined values.
final todoListPod = notifierPod<TodoList, List<Todo>>(TodoList.new);

/// The different ways to filter the list of todos
enum TodoListFilter {
  all,
  active,
  completed,
}

/// The currently active filter.
///
/// We use [statePod] here as there is no fancy logic behind manipulating
/// the value since it's just enum.
final todoListFilter = statePod(TodoListFilter.all);

/// The number of uncompleted todos
///
/// By using [pod], this value is cached, making it performant.\
/// Even multiple widgets try to read the number of uncompleted todos,
/// the value will be computed only once (until the [TodoList] changes).
///
/// This will also optimise unneeded rebuilds if the [TodoList] changes, but the
/// number of uncompleted [Todo]s doesn't (such as when editing a [Todo]).
final uncompletedTodosCount = pod<int>((ref) {
  return ref.watch(todoListPod).where((todo) => !todo.completed).length;
});

/// The list of todos after applying of [todoListFilter].
///
/// This too uses [pod], to avoid recomputing the filtered list unless either
/// the filter of or the [TodoList] updates.
final filteredTodos = pod<List<Todo>>((ref) {
  final filter = ref.watch(todoListFilter);
  final todos = ref.watch(todoListPod);

  switch (filter) {
    case TodoListFilter.completed:
      return todos.where((todo) => todo.completed).toList();
    case TodoListFilter.active:
      return todos.where((todo) => !todo.completed).toList();
    case TodoListFilter.all:
      return todos;
  }
});

/// A [pod] for New [Todo] TextEditingController.
final newTodoTextController = pod((_) => TextEditingController());

void main() {
  runApp(const PodScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final todos = context.watch(filteredTodos);
    final newTodoController = context.watch(newTodoTextController);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: [
            const Title(),
            TextField(
              key: addTodoKey,
              controller: newTodoController,
              decoration: const InputDecoration(
                labelText: 'What needs to be done?',
              ),
              onSubmitted: (value) {
                context.read(todoListPod.notifier).add(value);
                newTodoController.clear();
              },
            ),
            const SizedBox(height: 42),
            const Toolbar(),
            if (todos.isNotEmpty) const Divider(height: 0),
            for (var i = 0; i < todos.length; i++) ...[
              if (i > 0) const Divider(height: 0),
              Dismissible(
                key: ValueKey(todos[i].id),
                onDismissed: (_) {
                  context.read(todoListPod.notifier).remove(todos[i]);
                },
                child: TodoItem(todo: todos[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Toolbar extends StatelessWidget {
  const Toolbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final filter = context.watch(todoListFilter);

    Color? textColorFor(TodoListFilter value) {
      return filter == value ? Colors.blue : Colors.black;
    }

    return Material(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${context.watch(uncompletedTodosCount)} items left',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            key: allFilterKey,
            message: 'All todos',
            child: TextButton(
              onPressed: () => context.set(todoListFilter, TodoListFilter.all),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor:
                    MaterialStateProperty.all(textColorFor(TodoListFilter.all)),
              ),
              child: const Text('All'),
            ),
          ),
          Tooltip(
            key: activeFilterKey,
            message: 'Only uncompleted todos',
            child: TextButton(
              onPressed: () =>
                  context.set(todoListFilter, TodoListFilter.active),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TodoListFilter.active),
                ),
              ),
              child: const Text('Active'),
            ),
          ),
          Tooltip(
            key: completedFilterKey,
            message: 'Only completed todos',
            child: TextButton(
              onPressed: () =>
                  context.set(todoListFilter, TodoListFilter.completed),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TodoListFilter.completed),
                ),
              ),
              child: const Text('Completed'),
            ),
          ),
        ],
      ),
    );
  }
}

class Title extends StatelessWidget {
  const Title({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'todos',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color.fromARGB(38, 47, 47, 247),
        fontSize: 100,
        fontWeight: FontWeight.w100,
        fontFamily: 'Papyrus',
      ),
    );
  }
}

/// The widget that that displays the components of an individual [TodoItem]
class TodoItem extends StatelessWidget {
  const TodoItem({required this.todo, super.key});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final textEditingController =
        context.use(TextEditingController.new, id: 'textEditing');
    final itemFocusNode = context.use(FocusNode.new, id: 'itemFocus');
    final textFieldFocusNode = context.use(FocusNode.new, id: 'textFieldFocus');

    return Material(
      color: Colors.white,
      elevation: 6,
      child: Focus(
        focusNode: itemFocusNode,
        onFocusChange: (focused) {
          if (focused) {
            textEditingController.text = todo.description;
          } else {
            // Commit changes only when the textfield is unfocused,
            // for performance
            context.read(todoListPod.notifier).edit(
                  id: todo.id,
                  description: textEditingController.text,
                );
          }
        },
        child: ListTile(
          onTap: () {
            itemFocusNode.requestFocus();
            textFieldFocusNode.requestFocus();
          },
          leading: Checkbox(
            value: todo.completed,
            onChanged: (value) =>
                context.read(todoListPod.notifier).toggle(todo.id),
          ),
          title: itemFocusNode.hasFocus
              ? TextField(
                  autofocus: true,
                  focusNode: textFieldFocusNode,
                  controller: textEditingController,
                )
              : Text(todo.description),
        ),
      ),
    );
  }
}
