library client_collection_service;

import 'collection_messages.dart';
import '../messaging/messaging.dart';
import '../messaging/client_websocket_controller.dart';
import 'dart:async';
import '../../index.dart';
import 'package:quiver/check.dart';

class Collection<K, T> {
    
    final String collectionName;
    
    Collection(String collectionName) : collectionName = checkNotNull(collectionName);
    
    Filter filter;
    int page_size = 100;
    
    Exchange userExchange;
    
    int _collectionSize;
    int get collectionSize => _collectionSize;
    
    final List<T> _list = [];
    
    Future open() => new Future(() {
        _list.clear();
        if(userExchange != null) {
            userExchange.dispose();
        }
        userExchange = comms.newExchange();
        userExchange.sendRequest(new OpenCollection(userCollectionName, filter)).then((Message reply) {
            if(reply is OpenCollectionSuccess) {
                _list.addAll(reply.values);
                _collectionSize = reply.collectionSize;
                return;
            }
            else throw(reply.comment);
        });
    });

    
    
}
