library posts_messages;

import '../mail/mail_message.dart';
import 'package:quiver/check.dart';

void registerPostsMessages() {
    Message.factories.addAll({
        CreatePost.NAME          : (json) => new CreatePost.fromJson(json),
    });
}

class CreatePost extends Request {
    static final String NAME = "CreatePost";
    
    final Post post;
    
    CreatePost.fromJson(Map<String, dynamic> json) : 
        super.fromJson(json), 
        post = new Post.fromJson(checkNotNull(json['post']));
    
    CreatePost(Post post) : super(NAME), post = post {
        json['post'] = post.json;
    }
}

class Post extends Value {
    
    Post.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    Post(String userId, String text, {bool isImportant : false, bool isTask : false, bool isStrikethrough : false}) : this.fromJson({
        'userId' : checkNotNull(userId),
        'text' : text != null ? text : "",
        'isImporant' : isImportant,
        'isTask' : isTask,
        'isStrikethrough' : isStrikethrough,
    });
    
    String get userId           => json['userId'];
    String get text             => json['text'];
    bool   get isImportant      => json['isImportant'];
    bool   get isTask           => json['isTask'];
    bool   get isStrikethrough  => json['isStrikethrough'];
}