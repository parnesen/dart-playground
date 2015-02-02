library playgroundNest;

import 'package:polymer/polymer.dart';
import '../../lib/app/users/user_messages.dart';
import '../../index.dart';
import '../../lib/messaging/messaging.dart';
import '../../lib/collections/collection_messages.dart';
import 'dart:html';
import '../../lib/util.dart';
import 'package:quiver/check.dart';
import '../../lib/app/posts/client_post_service.dart';
import '../../lib/app/posts/post_messages.dart';
import 'dart:async';


@CustomTag('post-tile')
class PostTile extends PolymerElement { PostTile.created() : super.created();
    
    @observable String userId;
    @observable String firstName;
    @observable String lastName;
    
    @nonNull User user;
    bool isAttached = false;
    StreamSubscription newPostsSubscription;
    
    DivElement postsDiv;
    
    factory PostTile(User user) {
        return (new Element.tag('post-tile') as PostTile)
                ..user      = checkNotNull(user)
                ..userId    = user.userId
                ..firstName = user.firstName
                ..lastName  = user.lastName;
    }
    
    void attached() {
        isAttached = true;
        postsDiv = $['posts'];
        posts.whenInitialized.then((_) => addPosts(posts.from(userId)));
        
        newPostsSubscription = posts.newPostsFrom(userId).listen((Post post) => addPosts([posts]));
    }
    
    void detached() {
        isAttached = false;
        newPostsSubscription.cancel();
    }
    
    void addPosts(Iterable<Post> posts) {
        if(!isAttached) { return; }
        for(Post post in posts) {
            DivElement postElement = new DivElement()..innerHtml = post.text;
            postsDiv.children.add(postElement);
        }
    }
    
}




