library server_broadcaster;

import 'messaging/messaging.dart';

class Broadcaster {
    
    List<BroadcastResponder> responders;
    
    
    void broadcast(Message message) {
        responders.forEach((responder) => responder.send(message));
    }
}

class BroadcastResponder extends Responder {
    
    Broadcaster broadcaster;
    
    BroadcastResponder(this.broadcaster, CommsEndpoint endpoint, int exchangeId, {isSingleReply : true, bool requiresLogin : true, bool requiresAdminStatus : false}) 
      : super(endpoint, exchangeId, isSingleReply: isSingleReply, requiresLogin: requiresLogin, requiresAdminStatus: requiresAdminStatus);
   
    void dispose() {
        broadcaster.responders.remove(this);
    }
}