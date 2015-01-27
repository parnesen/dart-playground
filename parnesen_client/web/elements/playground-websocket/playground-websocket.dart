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
    @observable String outputString = "";
    @observable String inputString = "";
    
    StreamSubscription<StateTransition> stateSubscription;
    
    InputElement input;
    DivElement userEvents;
    Exchange userExchange;
    
    void attached() {
        
        log.info("playground-websocket attached");
        
        input       = $['input'  ];
        userEvents  = $['userEvents'];
        
        bool isEnterKey(KeyboardEvent event) => event.keyCode == KeyCode.ENTER;
        
        input.onKeyPress.where(isEnterKey).listen((_) => createUser());
        
        stateSubscription = webSocketController.stateTransitions.listen((StateTransition transition) {
            connectionState = transition.newState;
        });
        
        userExchange = comms.newExchange()
            ..stream
                .where((Message message) => isCollectionUpdate(message))
                .listen(onUserCollectionMsg);
        
        webSocketController.open().then((_) {
            userExchange.sendRequest(new OpenCollection(userCollectionName, new Filter()))
                .then((Message reply) => outputString = reply.isSuccess ? "UserCollection Open" : "Failed to open UserCollection: $reply");
        });
    }
    
    void onUserCollectionMsg(Message update) {
        userEvents.children.add(new DivElement()..innerHtml = update.toString());
    }
    
    void createUser() {
        User user = new User(inputString, "Patrick", "Arnesen", "Developer", "patrick.arnesen@gmail.com", unhashedPassword: "${inputString}_pwd");
        userExchange.sendRequest(new CreateValues([user]))
            .then((Message reply) => outputString = reply.isSuccess ? reply.comment : "request failed: ${reply}");
    }
    
    void submitPost() {
        Post post = new Post("user1", inputString);
        comms.send(new CreatePost(post)).then(
            (Message reply) => outputString = reply.isSuccess ? reply.comment : "request failed: ${reply}");
    }
    
    void goHome() => Route.home.go();
    
    void detached() {
        super.detached();
        userExchange.dispose();
        stateSubscription.cancel();
        webSocketController.close();
        
    }
    

}


