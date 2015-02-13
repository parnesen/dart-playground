library posts_messages;

import '../../messaging/messaging.dart';
import '../../util.dart';

void registerPostMessages() {
    JsonObject.factories.addAll({
        Post.NAME                : (json) => new Post.fromJson(json),
    });
}

const String postCollectionName = "PostCollection";

class Post extends KeyedJsonObject<int> {
    static const String NAME = "Post";
    
    Post.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    Post(String text, { String userId, int postId, bool isImportant : false, DateTime timestamp, bool isTask : false, bool isStrikethrough : false}) : super(NAME) {
        if(postId != null) { json['postId'] = postId; }
        if(isSet(userId))  { json['userId'] = userId; }
        json['text']   = checkNotEmpty(text);
        json['isImportant'] = isImportant;
        json['isTask'] = isTask;
        if(timestamp != null) { json['timestamp'] = timestamp.toString(); }
        json['isStrikethrough'] = isStrikethrough;
    }
    
    int    get key              => postId;
    int    get postId           => json['postId'];
    String get userId           => json['userId'];
    String get text             => json['text'];
    bool   get isImportant      => json['isImportant'];
    bool   get isTask           => json['isTask'];
    bool   get isStrikethrough  => json['isStrikethrough'];
    
    DateTime get timestamp {
        String str = json['timestamp'];
        return str != null ? DateTime.parse(str) : null;
    }
}