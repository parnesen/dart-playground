import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import '../../lib/messaging/client_websocket_controller.dart';
import '../../lib/messaging/messaging.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import '../../index.dart';
import '../../lib/app/posts/client_post_service.dart';
import '../../lib/app/posts/post_messages.dart';
import '../../lib/collections/collection_messages.dart';

final Logger log = new Logger('PostsPage');

@CustomTag('post-page')
class PostsPage extends PolymerElement {
    PostsPage.created() : super.created();
    
    @observable String output;
    @observable String postText;
    
    void attached() {
        super.attached();
        posts.whenInitialized.then((_) {
            output = "Post Collection Open";
        });
    }
    
    void detached() {
        super.detached();
    }
    
    void submitPost() {
        posts.exchange.sendRequest(new CreateValue(new Post(postText)))
            .then((Result result) {
                if(result is ValueCreated<Post>) {
                    output = "Post Submitted: '${result.value.timestamp}'";
                }
                else { throw result; }
            })
            .catchError((error) {
                String errorMsg = "Error Submitting Post: $error";
                log.warning(errorMsg);
                output = errorMsg;
            });
    }
    
    void goHome() => Route.home.go();
        

    

}


