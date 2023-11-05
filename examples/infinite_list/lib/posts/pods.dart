import 'package:flutter_pod/flutter_pod.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_list/posts/notifier.dart';
import 'package:infinite_list/posts/post.dart';

final httpClientPod = pod((ref) => http.Client()).keepAlive();

final hasPostsReachedMaxPod = statePod(false);

final postsNotifierPod =
    asyncNotifierPod<PostsNotifier, List<Post>>(PostsNotifier.new);
