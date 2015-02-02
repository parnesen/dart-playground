library client_post_service;

import '../../messaging/messaging.dart';
import '../../collections/collection_messages.dart';
import '../../../index.dart';
import 'dart:async';
import '../../initializable.dart';
import 'post_messages.dart';
import 'package:logging/logging.dart' show Logger;

final Logger log = new Logger('ClientPostService');

final ClientPostService posts = new ClientPostService();

class ClientPostService extends Initializable<ClientPostService> {
    
    final List<Post> all = [];
    
    StreamController<Post> _newPosts = new StreamController.broadcast();
    Stream<Post> get newPosts => _newPosts.stream;
    
    Iterable<Post> from(String userId)       => all.where(      (Post post) => post.userId == userId);
    Stream<Post> newPostsFrom(String userId) => newPosts.where( (Post post) => post.userId == userId);
    
    final Exchange exchange = comms.newExchange();
    
    ClientPostService() {
        addDependencies([comms]).listen((_) {
            if(comms.initialized) {
                attemptInitialize();
            }
            else {
                setInitialized(false);
            }
        });
        
        exchange.stream
            .where((Message message) => Message is ValuesCreated)
            .listen((ValuesCreated<Post> msg) {
                if(initialized) {
                    all.addAll(msg.values);
                    msg.values.forEach((Post post) => _newPosts.add(post));
                }
            });
        
        comms.whenLoggedIn.then((_) => attemptInitialize());
    }
    
    void attemptInitialize() {
        setInitialized(false);
        exchange.sendRequest(new OpenCollection(postCollectionName, new Filter(), fetchUpTo: 1000))
            .then((Result result) {
                if(!result.isSuccess) { throw result; }
                log.info("Post Collection Opened");
                return exchange.stream.firstWhere((Message message) => message is ReadResult);
            })
            .then((ReadResult<Post> read) {
                all..clear()..addAll(read.values);
                setInitialized(true);
            })
            .catchError((error) => log.warning("Error opening PostCollection: $error"));
    }
    
    void setInitialized(bool isInitialized) {
        if(!isInitialized) {
            all.clear();
        }
        super.setInitialized(isInitialized);
    }
}