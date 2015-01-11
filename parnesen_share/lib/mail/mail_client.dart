library mail_client;

import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'client_websocket_controller.dart';
import 'mail_message.dart';

/**
 * A simple Postoffice/Mailbox model for communicating to the server via json-based messages
 * All json values send and received must be maps. This is enforced via the Message class, which wraps the json. 
 */

final Logger log = new Logger('mail_client');

final PostOffice postOffice = new PostOffice._create();

int _requestCounter = 0;

class PostOffice {
    
    int _mailboxIdCounter = 0;
    final StreamController<Message> _broadcastController = new StreamController.broadcast();
    
    Map<int, Mailbox> _clientMailboxes = {};
    
    Stream<Message> get broadcastStream => _broadcastController.stream;
    
    PostOffice._create() {
        webSocketController.stream.listen(_handleMessage);
    }
    
    Mailbox createMailbox() {
        int mailboxId = ++_mailboxIdCounter;
        Mailbox mailbox = new Mailbox._create(mailboxId);
        _clientMailboxes[mailboxId] = mailbox;
        return mailbox;
    }
    
    void _handleMessage(String jsonString) {
        Message message = new Message.fromString(jsonString);
        if(message.mailboxId == null) {
            _broadcastController.add(message);
            return;
        }
        
        Mailbox mailbox = _clientMailboxes[message.mailboxId];
        if(mailbox == null) {
            log.warning("Invalid Mailbox Id: $message.mailboxId, ${message.name}");
            return;
        }
        
        mailbox._accept(message);
    }
}

class Mailbox {
    
    /** open requests awaiting a reply from the server **/
    final Map<int, Completer<Reply>> _completers = {}; 
    final StreamController<Message> _streamController = new StreamController.broadcast();
    final int id;
    Mailbox._create(int id) : this.id = id;
    
    /** messages streamed to this mailbox that are not a direct reply to a request **/
    Stream<Message> get stream => _streamController.stream;
    
    /** Send a request that triggers an asynchronous reply from the server **/
    Future<Reply> request(Request request) {
        final int requestId = ++_requestCounter;
        request.json['requestId'] = requestId;
        
        send(request);
        
        Completer<Reply> completer = new Completer();
        _completers[requestId] = completer;
        return completer.future;
    }
    
    /** send a message to the server that will not generate a reply **/
    void send(Message message) {
        message.json['mailboxId'] = id;
        webSocketController.send(JSON.encode(message.json));
    }
    
    void dispose() {
        postOffice._clientMailboxes.remove(id);
        for(Completer<Reply> completer in _completers.values) {
            completer.completeError("Mailbox was disposed");
        }
        _completers.clear();
        _streamController.close();
    }
    
    void _accept(Message message) {
        if(message is Reply) {
            _acceptReply(message);
        }
        else {
            _streamController.add(message);
        }
    }
   
    /**
     * a reply takes the shape of { name : 'reply', mailboxId : <int>, requestId : <int>, message : <json map>
     **/
    void _acceptReply(Reply reply) {
        int requestId = reply.requestId;
        Completer<Reply> completer = _completers.remove(requestId);
        if(completer == null) {
            log.warning("Response message received for which no completer could be found: $requestId, ${reply.requestName}");
            return;
        }
        completer.complete(reply);
    }
}

//class Message {
//    Map<String, dynamic> _json;
//    
//    /** json must be a map and must contain the field 'name' **/
//    Message(Map<String, dynamic> json) {
//        _json = checkNotNull(json) as Map; 
//    }
//    
//    Map<String, dynamic> get json => _json;
//    
//    String get name => json["name"];
//    
//    dynamic operator[](String fieldName) => json[fieldName];
//    void    operator[]=(String fieldName, dynamic value) => json[fieldName] = value;
//}


