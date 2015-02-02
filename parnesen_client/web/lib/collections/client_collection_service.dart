library client_collection_service;

import '../messaging/messaging.dart';
import 'collection_messages.dart';
import '../../index.dart';
import 'dart:async';
import '../initializable.dart';
import 'package:logging/logging.dart' show Logger;
import '../util.dart';

final Logger log = new Logger('ClientCollectionService');

class ClientCollectionService<K, V extends JsonObject> extends Initializable<ClientCollectionService<K, V>> {
    
    final List<V> all = [];
    
    StreamController<V> _newValues = new StreamController.broadcast();
    Stream<V> get newValues => _newValues.stream;

    final Exchange exchange = comms.newExchange();
    
    final String collectionName;
    
    ClientCollectionService(String collectionName) : collectionName = checkIsSet(collectionName) {
        addDependencies([comms]).listen((_) {
            if(comms.initialized) {
                attemptInitialize();
            }
            else {
                setInitialized(false);
            }
        });
        
        exchange.stream
            .where((message) => message is ValuesCreated)
            .listen((ValuesCreated<V> msg) {
                if(initialized) {
                    all.addAll(msg.values);
                    msg.values.forEach((V user) => _newValues.add(user));
                }
            });
        
        comms.whenLoggedIn.then((_) => attemptInitialize());
    }
    
    void attemptInitialize() {
        setInitialized(false);
        exchange.sendRequest(new OpenCollection(collectionName, new Filter(), fetchUpTo: 1000))
            .then((Result result) {
                if(!result.isSuccess) { throw result; }
                log.info("Collection $collectionName Opened");
                return exchange.stream.firstWhere((Message message) => message is ReadResult);
            })
            .then((ReadResult<V> read) {
                all..clear()..addAll(read.values);
                setInitialized(true);
            })
            .catchError((error) => log.warning("Error opening UserCollection: $error"));
    }
    
    void setInitialized(bool isInitialized) {
        if(!isInitialized) {
            all.clear();
        }
        super.setInitialized(isInitialized);
    }
}