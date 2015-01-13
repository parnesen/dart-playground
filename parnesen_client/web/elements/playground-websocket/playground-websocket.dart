import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import 'package:parnesen_share/mail/client_websocket_controller.dart';
import 'package:parnesen_share/mail/mail_client.dart';
import 'package:parnesen_share/mail/mail_share.dart';
import 'package:parnesen_share/messages/user_messages.dart';
import 'package:parnesen_share/messages/posts_messages.dart';

@CustomTag('playground-websocket')
class PlaygroundHome extends PolymerElement {
    
    PlaygroundHome.created() : super.created() {
        registerUserMessages();
        registerPostsMessages();
    }
    
    @observable State connectionState = webSocketController.state;
    @observable String outputString = "";
    @observable String inputString = "";
    
    StreamSubscription<String> messageSubscription;
    StreamSubscription<StateTransition> stateSubscription;
    
    InputElement input;
    DivElement results;
    
    Mailbox mailbox = postOffice.createMailbox();
    
    void attached() {
        
        print("playground-websocket attached");
        
        input   = $['input'  ] as InputElement;
        
        bool isEnterKey(KeyboardEvent event) => event.keyCode == KeyCode.ENTER;
        
        input.onKeyPress.where(isEnterKey).listen((_) => createUser());
        
        messageSubscription = webSocketController.stream.listen((String message) {
            print("message from server: " + message);
        });
        
        stateSubscription = webSocketController.stateTransitions.listen((StateTransition transition) {
            connectionState = transition.newState;
        });
          
        webSocketController.open();
    }
    
    void createUser() {
        print("createUser $inputString");
        CreateUserRequest createUser = new CreateUserRequest(inputString, "password");
        mailbox.sendRequest(createUser).single.then(
            (Message reply) => outputString = reply.isSuccess ? reply.comment : "request failed: ${reply}");
    }
    
    void submitPost() {
        print("submitPost $inputString");
        
        Post post = new Post("user1", inputString);
        mailbox.sendRequest(new CreatePost(post)).single.then(
            (Message reply) => outputString = reply.isSuccess ? reply.comment : "request failed: ${reply}");
    }
    
    void goHome() => Route.home.go();
    
    void detached() {
        super.detached();
        messageSubscription.cancel();
        stateSubscription.cancel();
        webSocketController.close();
    }
    

}


