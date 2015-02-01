import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import "package:polymer/polymer.dart";
import 'lib/messaging/client_websocket_controller.dart';
import 'lib/messaging/messaging.dart';
import 'lib/collections/collection_messages.dart';
import 'lib/app/users/user_messages.dart';
import 'lib/app/posts/posts_messages.dart';

final ClientWebsocketController webSocketController = new ClientWebsocketController();
final CommsEndpoint comms  = new CommsEndpoint.clientSide(webSocketController.send);

main() {
    
    Logger.root.level = Level.CONFIG;
    Logger.root.onRecord
        .listen((LogRecord rec) => print('${rec.loggerName}[${rec.level.name}] ${rec.time}: ${rec.message}'));
    
    webSocketController.stream.listen(comms.receive);
    
    webSocketController.stateTransitions.listen((StateTransition transition) {
        if(transition.newState != OpenState) {
            comms.isLoggedIn = false;
        }
    });
    
    registerUserMessages();
    registerPostsMessages();
    registerCollectionMessages();
    registerLoginMessages();

    initPolymer().run(() {
        // code here works most of the time

        Polymer.onReady.then((_) {     
            // some things must wait until onReady callback is called
            // for an example look at the discussion https://groups.google.com/a/dartlang.org/forum/#!msg/web/7cRLZerHmOo/v9eCBSP0-lYJ
        });
    });
}