import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_list_post.dart';

class RemoteService_list {
  Future<PostList?> getPostslist() async {
    var client = http.Client();

    var uri =
        Uri.parse('http://mirror.ccjjj.com/xcxapi/teacher/video_list?uid=777');
    var response = await client.post(uri);
  }
}
