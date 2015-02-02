import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import 'dart:html';
import '../../index.dart';
import 'dart:async';


@CustomTag('playground-home')
class PlaygroundHome extends PolymerElement {
    PlaygroundHome.created() : super.created();
    
    void goCounter()   => Route.counter     .go();
    void goNest()      => Route.nest        .go();
    void goUserPage()  => Route.users       .go();
    void goPostPage()  => Route.posts       .go();
    
    ButtonElement userButton, postButton;
    StreamSubscription commsInitUpdatesSubscription;
    
    void attached() {
        super.attached();
        
        userButton = $['userbtn'];
        postButton = $['postbtn'];
        
        commsInitUpdatesSubscription = comms.initUpdates.listen((_) => enableOrDisableButtons());
        enableOrDisableButtons();
    }
    
    void detached() {
        super.detached();
        commsInitUpdatesSubscription.cancel();
    }
    
    void enableOrDisableButtons() {
        bool isDisabled = !comms.isLoggedIn;
        userButton.disabled = isDisabled;
        postButton.disabled = isDisabled;
    }
}


