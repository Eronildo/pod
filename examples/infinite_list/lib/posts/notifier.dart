import 'dart:async';
import 'dart:convert';

import 'package:flutter_pod/flutter_pod.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_list/posts/pods.dart';
import 'package:infinite_list/posts/post.dart';

const _postLimit = 20;
const _throttleDuration = Duration(milliseconds: 100);

class PostsNotifier extends AsyncNotifier<List<Post>> {
  http.Client get httpClient => ref.watch(httpClientPod);

  @override
  FutureOr<List<Post>> build() => _fetchPosts();

  Future<void> fetchPosts() async {
    if (ref.read(hasPostsReachedMaxPod)) return;
    ref.throttle(
      () async {
        final posts = state.value;
        if (posts != null) {
          await guard(() async {
            final newPosts = await _fetchPosts(posts.length);
            if (newPosts.length < _postLimit) {
              ref.set(hasPostsReachedMaxPod, true);
            }
            return Future.value(List.of(posts)..addAll(newPosts));
          });
        }
      },
      duration: _throttleDuration,
    );
  }

  Future<List<Post>> _fetchPosts([int startIndex = 0]) async {
    final response = await httpClient.get(
      Uri.https(
        'jsonplaceholder.typicode.com',
        '/posts',
        <String, String>{'_start': '$startIndex', '_limit': '$_postLimit'},
      ),
    );
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as List;
      return body.map((dynamic json) {
        final map = json as Map<String, dynamic>;
        return Post(
          id: map['id'] as int,
          title: map['title'] as String,
          body: map['body'] as String,
        );
      }).toList();
    }
    throw Exception('error fetching posts');
  }
}
