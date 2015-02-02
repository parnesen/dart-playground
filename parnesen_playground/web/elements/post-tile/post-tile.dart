library playgroundNest;

import 'package:polymer/polymer.dart';
import '../../lib/app/users/user_messages.dart';
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
    StreamSubscription postServiceInitSubscription;
    
    DivElement postsContainer;
    
    factory PostTile(User user) {
        return (new Element.tag('post-tile') as PostTile)
                ..user      = checkNotNull(user)
                ..userId    = user.userId
                ..firstName = user.firstName
                ..lastName  = user.lastName;
    }
    
    void attached() {
        super.attached();
        isAttached = true;
        postsContainer = $['posts'];
        postServiceInitSubscription = posts.initUpdates.listen((_) => resetPosts());
        newPostsSubscription = posts.newPostsFrom(userId).listen((Post post) => addPost(post));
        resetPosts();
    }
    
    void detached() {
        super.detached();
        isAttached = false;
        newPostsSubscription.cancel();
        postServiceInitSubscription.cancel();
    }
    
    void resetPosts() {
        postsContainer.children.clear();
        if(posts.initialized) {
            posts.from(userId).forEach((post) => addPost(post));
        }
    }
    
    void addPost(Post post) {
        if(!isAttached) { return; }
        DivElement postElement = new DivElement()..innerHtml = post.text;
        postsContainer.children.add(postElement);
        postElement.scrollIntoView();
    }
}




