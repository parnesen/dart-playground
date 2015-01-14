library collection_handler;

import 'package:parnesen_share/mail/comms_endpoint.dart';
import 'package:parnesen_share/mail/mail_share.dart';
import 'collection_handler_messages.dart';

void registerRequestHandlers() {
    CommsEndpoint.requestHandlerFactories.addAll({
        GetCollection.NAME: (CommsEndpoint endpoint, Message request) => new CollectionHandler(endpoint, request.requestId)
    });
}

class CollectionHandler extends RequestHandler {
    CollectionHandler(CommsEndpoint endpoint, int requestId) : super(endpoint, requestId);
    
    void recieve(Message request) {
        
    }
}
