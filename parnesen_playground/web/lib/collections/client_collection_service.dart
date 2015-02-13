library client_collection_service;

import '../messaging/messaging.dart';
import 'collection_messages.dart';
import '../../index.dart';
import 'dart:async';
import '../initializable.dart';
import 'package:logging/logging.dart' show Logger;
import '../util.dart';

final Logger log = new Logger('ClientCollectionService');

class ClientCollectionService<K, V extends KeyedJsonObject<K>> extends Initializable<ClientCollectionService<K, V>> {
    
    final List<V> all = [];
    
    StreamController<V> _createEvents = new StreamController.broadcast();
    StreamController<V> _updateEvents = new StreamController.broadcast();
    StreamController<K> _deleteEvents = new StreamController.broadcast();
    
    Stream<V> get createEvents => _createEvents.stream;
    Stream<V> get updateEvents => _updateEvents.stream;
    Stream<K> get deleteEvents => _deleteEvents.stream;

    final Exchange exchange = comms.newExchange();
    
    bool get isOpen => exchange.isOpen;
    
    final String collectionName;
    
    ClientCollectionService(String collectionName) : collectionName = checkNotEmpty(collectionName) {
        addDependencies([comms]).listen((_) {
            if(comms.initialized) {
                _attemptInitialize();
            }
            else {
                setInitialized(false);
            }
        });
        
        exchange.stream.listen((Message msg) {
            if(!initialized) { return; }
            if     (msg is ValuesCreated<V>) { onCreate(msg); }
            else if(msg is ValuesUpdated<V>) { onUpdate(msg); }
            else if(msg is ValuesDeleted<K>) { onDelete(msg); }
        });
        
        comms.whenLoggedIn.then((_) => _attemptInitialize());
    }
    
    void dispose() => exchange.dispose();

    void onCreate(ValuesCreated<V> msg) {
        msg.values.forEach((V value) {
            all.add(value);
            _createEvents.add(value);
        });
    }
    
    void onUpdate(ValuesUpdated<V> msg) {
        msg.values.forEach((V update) {
            for(int ii = 0; ii < all.length; ii++) {
                if(all[ii].key == update.key) {
                    all[ii] = update;
                }
            }
            _updateEvents.add(update);
        });
    }
    
    void onDelete(ValuesDeleted<K> msg) {
        msg.keys.forEach((K key) {
            all.removeWhere((V value) => value.key == key);
            _deleteEvents.add(key);
        });
    }
    
    void _attemptInitialize() {
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