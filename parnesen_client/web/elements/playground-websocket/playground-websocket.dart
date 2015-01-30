import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import '../../lib/messaging/client_websocket_controller.dart';
import '../../lib/messaging/messaging.dart';
import '../../lib/app/users/user_messages.dart';
import '../../lib/app/posts/posts_messages.dart';
import '../../lib/collections/collection_messages.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import '../../index.dart';

final Logger log = new Logger('PlaygroundHome');

@CustomTag('playground-websocket')
class PlaygroundWebsocket extends PolymerElement {
    
    PlaygroundWebsocket.created() : super.created();
    
    @observable State connectionState = webSocketController.state;
    @observable String output = "";
    
    StreamSubscription<StateTransition> stateSubscription;
    
    InputElement input;
    DivElement userEvents;
    
    void attached() {
        
        log.info("playground-websocket attached");
        
        webSocketController.open().catchError((error) => output = "failed to connect: $error");
        
        userEvents  = $['userEvents'];
        
        bool isEnterKey(KeyboardEvent event) => event.keyCode == KeyCode.ENTER;
        
        stateSubscription = webSocketController.stateTransitions.listen((StateTransition transition) {
            connectionState = transition.newState;
        });
    }
    
    void onUserCollectionMsg(Message update) {
        userEvents.children.add(new DivElement()..innerHtml = update.toString());
    }
    
//    void submitPost() {
//        Post post = new Post("user1", inputString);
//        comms.sendRequest(new CreatePost(post))
//            .then((Result result) => outputString = result.isSuccess ? result.comment : "request failed: ${result}");
//    }
    
    void goHome() => Route.home.go();
    
    void reconnect() {
        output = "";
        webSocketController.open().catchError((error) => output = "failed to reconnect: $error");
    }
    
    void detached() {
        super.detached();
        stateSubscription.cancel();
        webSocketController.close();
    }
    

}


