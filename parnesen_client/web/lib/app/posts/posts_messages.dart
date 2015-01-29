library posts_messages;

import '../../messaging/messaging.dart';
import 'package:quiver/check.dart';

void registerPostsMessages() {
    JsonObject.factories.addAll({
        CreatePost.NAME          : (json) => new CreatePost.fromJson(json),
        Post.NAME                : (json) => new Post.fromJson(json),
    });
}

class CreatePost extends Request {
    static const String NAME = "CreatePost";
    
    final Post post;
    
    CreatePost.fromJson(Map<String, dynamic> json) 
        : super.fromJson(json) 
        , post = new Post.fromJson(checkNotNull(json['post']));
    
    CreatePost(Post post) : super(name : NAME), post = post {
        json['post'] = post.json;
    }
}

class Post extends JsonObject {
    static const String NAME = "Post";
    
    Post.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    Post(String userId, String text, {bool isImportant : false, bool isTask : false, bool isStrikethrough : false}) : super(NAME) {
        json['userId'] = checkNotNull(userId);
        if(text != null) { json['text'] = text; }
        json['isImportant'] = isImportant;
        json['isTask'] = isTask;
        json['isStrikethrough'] = isStrikethrough;
    }
    
    String get userId           => json['userId'];
    String get text             => json['text'];
    bool   get isImportant      => json['isImportant'];
    bool   get isTask           => json['isTask'];
    bool   get isStrikethrough  => json['isStrikethrough'];
}