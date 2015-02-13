library server_collection_service;

import '../messaging/messaging.dart';
import 'collection_messages.dart';
import 'package:quiver/check.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'dart:async';

final Logger log = new Logger('server_collection_service');

final CollectionService collectionService = new CollectionService._create();

typedef Collection CollectionFactory();

class CollectionService {
    
    static final Map<String, CollectionFactory> collectionFactories = {};
    
    final Map<String, Collection> _openCollections = {};
    
    CollectionService._create();
    
    static void init() {
        CommsEndpoint.responderFactories[OpenCollection.NAME] = collectionService.onOpenCollectionRequest;
    }
    
    Responder onOpenCollectionRequest(CommsEndpoint endpoint, OpenCollection request) =>
        openCollection(request.collectionName).newResponder(endpoint, request.exchangeId);
    
    Collection openCollection(String collectionName) {
        Collection collection = _openCollections[collectionName];
        if(collection == null) {
            CollectionFactory factory = collectionFactories[collectionName];
            checkState(factory != null, message : "No CollectionHandlerFactory registered for collection '$collectionName'");
            collection = factory();
            _openCollections[collectionName] = collection;
        }
        return collection;
    }
}

abstract class Collection<K, V extends KeyedJsonObject<K>> {
    
    final String collectionName;
    final Set<CollectionResponder> responders = new Set();
    
    Collection(collectionName) : collectionName = checkNotNull(collectionName);
    
    CollectionResponder newResponder(CommsEndpoint endpoint, int exchangeId) {
        CollectionResponder responder = new CollectionResponder(this, endpoint, exchangeId);
        responders.add(responder);
        responder.onClose.then(onResponderClosed);
        return responder;
    }
    
    void open(CollectionResponder responder, OpenCollection request, String collectionName, Filter filter, int fetchUpTo);
    void createValue(CollectionResponder responder, CreateValue request, V value);
    void createValues(CollectionResponder responder, CreateValues request, List<V> values);
    void readValues(CollectionResponder responder, ReadValues request, int startIndex, int count);
    void updateValues(CollectionResponder responder, UpdateValues request, List<V> values);
    void deleteValues(CollectionResponder responder, DeleteValues request, List<K> ids);
    
    void broadcast(Message message) {
        responders.forEach((responder) {
            responder.send(message);
        });
    }
    
    void onResponderClosed(Responder responder) {
        responders.remove(responder);
    }
}

class CollectionResponder extends Responder {
    
    final Collection collection;
    Filter filter;
    
    CollectionResponder(Collection collection, CommsEndpoint endpoint, int exchangeId) 
        : super(endpoint, exchangeId, isSingleReply : false, requiresLogin: true) 
        , collection = checkNotNull(collection) {
        
        this.requests.listen(onRequest);
    }
    
    void onRequest(Request request) {
        try {
            if(request is OpenCollection) {
                this.filter = request.filter;
                collection.open(this, request, request.collectionName, request.filter, request.fetchUpTo);
            }
            else if (request is CreateValue) {
                collection.createValue(this, request, request.value);
            }
            else if (request is CreateValues) {
                collection.createValues(this, request, request.values);
            }        
            else if (request is ReadValues) {
                collection.readValues(this, request, request.startIndex, request.count);
            }
            else if(request is UpdateValues) {
                collection.updateValues(this, request, request.values);
            }        
            else if(request is DeleteValues) {
                collection.deleteValues(this, request, request.keys);
            }
            else {
                log.warning("CollectionRequestHandler doesn't handle request ${request.name}");
            }
        }
        catch(error, stacktrace) {
            String errorMsg = "unexpected error handling request: $error";
            log.warning(errorMsg, error, stacktrace);
            sendFail(request, errorMsg: errorMsg);
            print(stacktrace);
        }
    }
    
    /** Configures the given [message] message as a reply and sends it **/
    Stream<Message> send(Message message, { bool isFinal, String comment : null }) {        
        Stream<Message> stream = super.send(message, isFinal: isFinal, comment: comment);
        if(!isOpen) { //sending the message will have closed the exchange if the message was flagged as final
            collection.responders.remove(this);
        }
        return stream;
    }
}



