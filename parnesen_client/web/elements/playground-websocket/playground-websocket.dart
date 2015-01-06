import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import '../../services/client_websocket_controller.dart';

@CustomTag('playground-websocket')
class PlaygroundHome extends PolymerElement {
    PlaygroundHome.created() : super.created();
    
    @observable String inputString = "";
    @observable String outputString = "";
    @observable State connectionState = webSocketController.state;
    
    StreamSubscription<String> messageSubscription;
    StreamSubscription<StateTransition> stateSubscription;
    
    InputElement input;
    DivElement results;
    
    void attached() {
        
        print("playground-websocket attached");
        
        input   = $['input'  ] as InputElement;
        results = $['results'] as DivElement;
        
        bool isEnterKey(KeyboardEvent event) => event.keyCode == KeyCode.ENTER;
        
        input.onKeyPress.where(isEnterKey).listen((_) => submit());
        
        messageSubscription = webSocketController.stream.listen((String message) {
            print("message from server: " + message);
            outputString = message;
            DivElement child = new DivElement()..innerHtml = message;
            results.children.add(child);
        });
        
        stateSubscription = webSocketController.stateTransitions.listen((StateTransition transition) {
            connectionState = transition.newState;
        });
          
        webSocketController.open();
    }
    
    void submit() => webSocketController.send(inputString);
    void goHome() => Route.home.go();
    void clear()  => results.children.clear();
    
    void detached() {
        super.detached();
        messageSubscription.cancel();
        stateSubscription.cancel();
        webSocketController.close();
    }
    

}


