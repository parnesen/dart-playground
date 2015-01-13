library mail_client;

import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'client_websocket_controller.dart';
import 'mail_share.dart';
import 'package:quiver/check.dart';

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
        Message message = jsonToMessage(JSON.decode(jsonString));
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
    final Map<int, StreamController<Message>> _requestStreams = {};
    
    /** stream for incomming messages directed at this mailbox in general but not in response to a particular request **/
    final StreamController<Message> _mailboxStream = new StreamController.broadcast();
    final int id;
    Mailbox._create(int id) : this.id = id;
    
    /** messages streamed to this mailbox that are not replies to a request **/
    Stream<Message> get stream => _mailboxStream.stream;
    
    /** 
     * Send a request that triggers an asynchronous reply from the server 
     * Returns a Stream that will close when a Message marked isFinal=true is received from the server.
     * All server-generated error messages are treated as normal messages by the stream. 
     * For Stream errors, see subclasses of [RequestStreamError]
     **/
    Stream<Message> sendRequest(Message request) {
        checkState(request.requestId == null);
        checkState(request.isFinal == false);
        checkState(request.result == Result.Unspecified);
  
        final int requestId = ++_requestCounter;
        request.json['requestId'] = requestId;
        
        StreamController<Message> streamController = new StreamController()
            ..done.then((_) => _requestStreams.remove(requestId));
        _requestStreams[requestId] = streamController;
        
        send(request);
        return streamController.stream;
    }
    
    /** Send a message to the server that will not generate a reply **/
    void send(Message message) {
        checkState(message.mailboxId == null || message.mailboxId == id);
        message.json['mailboxId'] = id;
        webSocketController.send(JSON.encode(message.json));
    }
    
    void _accept(Message message) {
        int requestId = message.requestId;
        if(requestId == null) {
            _mailboxStream.add(message);
            return;
        }
        
        StreamController<Message> requestStream = 
            message.isFinal  ? _requestStreams.remove(requestId) 
                             : _requestStreams['requsetId'];
                
        if(requestStream == null) {
            log.warning("Reply message received for which no reply Stream could be found: $message");
            return;
        }
        
        requestStream.add(message);
        if(message.isFinal || message.isFail) {
            requestStream.close();
        }
    }
   
    void dispose() {
        postOffice._clientMailboxes.remove(id);
        bool hadUnfinishedRequests = false;
        _requestStreams.forEach((int requestId, StreamController stream) {
            hadUnfinishedRequests = true;
            stream.addError(new StreamDisposedError());
            stream.close();
         });
        
        if(hadUnfinishedRequests) {
            log.warning("Disposed Mailbox $id had unfinished requests");
        }
        
        _requestStreams.clear();
        _mailboxStream.close();
    }
}

abstract class RequestStreamError { }
class StreamDisposedError   extends RequestStreamError { } 
class TimeoutError          extends RequestStreamError { }
