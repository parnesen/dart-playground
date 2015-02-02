import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import '../../lib/messaging/messaging.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import '../../index.dart';
import '../../lib/app/users/client_user_service.dart';
import '../../lib/app/users/user_messages.dart';
import '../../lib/collections/collection_messages.dart';
import '../../lib/app/posts/client_post_service.dart';
import '../../lib/app/posts/post_messages.dart';

import '../post-tile/post-tile.dart';

final Logger log = new Logger('PostsPage');

@CustomTag('post-page')
class PostsPage extends PolymerElement {
    PostsPage.created() : super.created();
    
    @observable String output;
    @observable String postText;
    
    bool isAttached;
    
    StreamSubscription newUserSubscription;
    
    String get userId => comms.userId;
    
    Element tileContainer;
    
    final Map<String, PostTile> tiles = {};
    
    void attached() {
        super.attached();
        isAttached = true;
        tileContainer = $['tiles'];
        users.whenInitialized.then((_) {
            output = "User Collection Open";
            users.all.forEach((user) => createTile(user));
        });
        
        newUserSubscription = users.newValues.listen(createTile);
    }
    
    void detached() {
        super.detached();
        isAttached = false;
        newUserSubscription.cancel();
    }
    
    void submitPost() {
        posts.exchange.sendRequest(new CreateValue(new Post(postText)))
            .then((Result result) {
                if(result is ValueCreated<Post>) {
                    Post post = result.value;
                    log.info("Post Submitted: $post.json");
                    output = "Post Submitted: ${post.timestamp}";
                }
            })
            .catchError((error) {
                String errorMsg = "Error Submitting Post: $error";
                log.warning(errorMsg);
                output = errorMsg;
            });
    }
    
    PostTile getTile(User user) {
        PostTile tile = tiles[user.userId];
        if(tile == null) {
            tile = createTile(user);
        }
        return tile;
    }
    
    PostTile createTile(User user) {
        PostTile tile = new PostTile(user);
        tileContainer.children.add(tile);
        tiles[user.userId] = tile;
        return tile;
    }
    
    void goHome() => Route.home.go();

}


