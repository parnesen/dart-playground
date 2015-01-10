import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import '../../services/client_websocket_controller.dart';
import '../../services/mail_client.dart';
import 'package:parnesen_share/messages/mail_share.dart';

@CustomTag('playground-websocket')
class PlaygroundHome extends PolymerElement {
    PlaygroundHome.created() : super.created();
    
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
          
        
    }
    
    void createUser() {
        mailbox.request(new CreateUser(inputString, "password")).then((Reply reply){
            if(reply is Success) {
                outputString = reply.message;
            }
            else if(reply is Fail) {
                outputString = reply.errorMessage;
            }
            else {
                outputString = "unexpected reply: ${reply.name}";
            }
        });
        
        print("createUser $inputString");
    }
    
    void post() {
        Post post = new Post("user1", inputString);
        mailbox.request(new CreatePost(post)).then((Reply reply) {
            if(reply is Success) {
                outputString = reply.message;
            }
            else if(reply is Fail) {
                outputString = reply.errorMessage;
            }
            else {
                outputString = "unexpected reply: ${reply.name}";
            }
        });
    }
    
    void goHome() => Route.home.go();
    
    void detached() {
        super.detached();
        messageSubscription.cancel();
        stateSubscription.cancel();
        webSocketController.close();
    }
    

}


