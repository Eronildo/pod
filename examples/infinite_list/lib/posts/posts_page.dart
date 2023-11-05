import 'package:flutter/material.dart';
import 'package:flutter_pod/flutter_pod.dart';
import 'package:hook_it/hook_it.dart';
import 'package:infinite_list/posts/pods.dart';
import 'package:infinite_list/posts/widgets/bottom_loader.dart';
import 'package:infinite_list/posts/widgets/post_list_item.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = context.use(
      ScrollController.new,
      id: 'scroll',
      listener: (controller) {
        bool isBottom() {
          if (!controller.hasClients) return false;
          final maxScroll = controller.position.maxScrollExtent;
          final currentScroll = controller.offset;
          return currentScroll >= (maxScroll * 0.9);
        }

        if (isBottom()) context.read(postsNotifierPod.notifier).fetchPosts();
      },
    );
    final asyncPosts = context.watch(postsNotifierPod);

    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: Center(
        child: asyncPosts.when(
          data: (posts) => posts.isEmpty
              ? const Text('no posts')
              : ListView.builder(
                  itemBuilder: (_, int index) {
                    return index >= posts.length
                        ? const BottomLoader()
                        : PostListItem(post: posts[index]);
                  },
                  itemCount: context.watch(hasPostsReachedMaxPod)
                      ? posts.length
                      : posts.length + 1,
                  controller: scrollController,
                ),
          error: (_, __) => const Text('failed to fetch posts'),
          loading: () => const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
