library server_collection_service;

import '../messaging/messaging.dart';
import 'collection_messages.dart';
import 'package:quiver/check.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;

final Logger log = new Logger('server_collection_service');

final CollectionService collectionService = new CollectionService._create();

typedef Collection CollectionFactory();

class CollectionService {
    
    static final Map<String, CollectionFactory> collectionFactories = {};
    
    final Map<String, Collection> _openCollections = {};
    
    CollectionService._create();
    
    static void init() {
        CommsEndpoint.responderFactories[OpenCollection.NAME] = collectionService.openCollection;
    }
    
    Responder openCollection(CommsEndpoint endpoint, OpenCollection request) {
        String collectionName = request.collectionName;
        Collection collection = _openCollections[collectionName];
        if(collection == null) {
            CollectionFactory factory = collectionFactories[collectionName];
            checkState(factory != null, message : "No CollectionHandlerFactory registered for collection '$collectionName'");
            collection = factory();
            _openCollections[collectionName] = collection;
        }
        
        Responder responder = collection.newResponder(endpoint, request.exchangeId);
        return responder;
    }
}

abstract class Collection<K, T> {
    
    final String collectionName;
    
    Collection(collectionName) : collectionName = checkNotNull(collectionName);
    
    Set<CollectionResponder> responders = new Set();
    
    CollectionResponder newResponder(CommsEndpoint endpoint, int exchangeId) {
        CollectionResponder responder = new CollectionResponder(this, endpoint, exchangeId);
        responders.add(responder);
        responder.onClose.then((_) => responders.remove(responder));
        return responder;
    }
    
    void open(Request request, String collectionName, Filter filter, int fetchUpTo);
    void createValues(Request request, List<T> values);
    void readValues(Request request, int startIndex, int count);
    void updateValues(Request request, List<T> values);
    void deleteValues(Request request, List<K> ids);
    
    void broadcast(Message message) {
        responders.forEach((responder) {
            responder.send(message);
        });
    }
}

class CollectionResponder extends Responder {
    
    final Collection collection;
    Filter filter;
    
    CollectionResponder(Collection collectionHandler, CommsEndpoint endpoint, int exchangeId) 
        : super(endpoint, exchangeId, isSingleReply : false) 
        , collection = checkNotNull(collectionHandler) {
        
        this.requests.listen(onRequest);
    }
    
    void onRequest(Request request) {
        Message message = request.message;
        if(message is OpenCollection) {
            this.filter = message.filter;
            collection.open(request, message.collectionName, message.filter, message.fetchUpTo);
        }
        else if (message is CreateValues) {
            collection.createValues(request, message.values);
        }        
        else if (message is ReadValues) {
            collection.readValues(request, message.startIndex, message.count);
        }
        else if(message is UpdateValues) {
            collection.updateValues(request, message.values);
        }        
        else if(message is DeleteValues) {
            collection.deleteValues(request, message.keys);
        }
        else {
            log.warning("CollectionRequestHandler doesn't handle request ${message.name}");
        }
    }
}



