import 'package:flutter/material.dart';
import 'package:flutter_pod/flutter_pod.dart';
import 'package:infinite_list/posts/posts_page.dart';

void main() {
  runApp(const PodScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PostsPage(),
    );
  }
}
