library client_post_service;

import 'dart:async';
import 'post_messages.dart';
import '../../collections/client_collection_service.dart';

final ClientPostService posts = new ClientPostService();

class ClientPostService extends ClientCollectionService<int, Post> {
    ClientPostService() : super(postCollectionName);
    
    Iterable<Post> from(String userId)       => all.where(      (Post post) => post.userId == userId);
    Stream<Post> newPostsFrom(String userId) => newValues.where( (Post post) => post.userId == userId);
}