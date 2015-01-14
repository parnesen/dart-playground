library comms_endpoint;

import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'mail_share.dart';
import 'package:quiver/check.dart';

/**
 * A simple Postoffice/Mailbox model for communicating to the server via json-based messages
 * All json values send and received must be maps. This is enforced via the Message class, which wraps the json. 
 */

final Logger log = new Logger('comms_endpoint');

/** Websockets on client and server are two different types without a common baseclass */
abstract class WebSocketProxy {
    void send(data);
}

typedef RequestHandler RequestHandlerFactory(CommsEndpoint endpoint, Message request);

class CommsEndpoint {
    
    static final Map<String, RequestHandlerFactory> requestHandlerFactories = {};
    
    final bool isClientSide;
    bool get   isServerSide => !isClientSide;
    
    //TODO: handle websocket closure
    final WebSocketProxy webSocketProxy;
    
    /** open requests that originated from this local [CommsEndoint]**/
    final Map<int, Request> _requests = {};
    
    /** handlers for requests that originated from the remote [CommsEndpoint] **/
    final Map<int, RequestHandler> _requestHandlers = {}; 

    /** 
     *  if [side] is Client then the id of the first request initiated on this side will be 1 and subsequent ids will be > 
     *  if [side] is Server then the id of the first request initiated on this side will be -1 and subsequent ids will be <
     */
    int _requestCounter = 0;
    int _lastHandledRequest = 0;
    
    CommsEndpoint.clientSide(WebSocketProxy webSocketProxy)
        : isClientSide = true
        , webSocketProxy = checkNotNull(webSocketProxy);
    
    CommsEndpoint.serverSide(WebSocketProxy webSocketProxy)
        : isClientSide = false
        , webSocketProxy = checkNotNull(webSocketProxy);
    
    /** 
     * sends a single request to the remote [CommsEndpoint] and returns a future for the single expected reply.
     * Use this method for simple single-request/single-reply interop. 
     * 
     * For more complex client-server interop use the [newRequest] method to create
     * a [Request] object through which multiple messages can be sent or received.
     **/
    Future<Message> send(Message message) => newRequest().send(message).single;    
    
    Request newRequest() {
        int requestId = isClientSide ? ++_requestCounter : --_requestCounter;
        Request request = new Request._create(this, requestId);
        _requests[requestId] = request;
        return request;
    }

    void receive(String jsonString) {
        Message message;
        try {
            message = jsonToObj(JSON.decode(jsonString));
        }
        catch(error) {
            log.warning("Unable to parse string as Message: '$jsonString' due to error $error");
            return;
        }
        
        int requestId = message.requestId;
        
        void logAndSendError(String errorMessage) {
            log.warning(errorMessage);
            GenericFail fail = new GenericFail(errorMessage);
            fail.json['requestId'] = requestId;
            _send(new GenericFail(errorMessage)); 
        }
                
        if(isRequestOriginatedHere(requestId)) {
            Request request = _requests[requestId];
            if(request == null) {
                logAndSendError("No Request instance could be found for message $message");
            }
            log.info("Handling Message $message");
            
            log.info("Request instance receiving message $message");
            request._recieve(message);
        }
        else {
            RequestHandler handler;
            bool isNewRequest = (requestId > 0) ? (requestId > _lastHandledRequest) : (requestId < _lastHandledRequest);
            
            if(isNewRequest) { 
                _lastHandledRequest = requestId;
                RequestHandlerFactory factory = requestHandlerFactories[message.name];
                if(factory == null) {
                    logAndSendError("$this: No RequestHandlerFactory registered for message of type ${message.name}");                   
                    return;
                }
                handler = factory(this, message);
                _requestHandlers[requestId] = handler;
            }
            else {
                handler = _requestHandlers[requestId];
                if(handler == null) {
                    logAndSendError("$this recieved a message for which the requestHandler has expired: ${message.name}");
                    return;
                }
            }
            
            log.info("RequestHandler receiving message $message");
            handler.recieve(message);
        }
    }
    
    bool isRequestOriginatedHere(int messageRequestId) => isClientSide ? messageRequestId > 0 : messageRequestId < 0;    
    
    String toString() => "CommsEndpoint[${isClientSide ? "ClientSide" : "ServerSide"}]";
    
    /** Internal method used by [Request] and [RequestHandler] to send fully prepared messages to the remote [CommsEndpoint]**/
    void _send(Message message) {
        log.info("Sending Message $message");
        checkState(message.requestId != null);
        String str = JSON.encode(message.json); 
        webSocketProxy.send(str);
    }
}

/** represents a request that was started from this side of the CommsEndpoint **/
class Request {
    
    final CommsEndpoint endpoint;
    final int id;
    final StreamController<Message> _streamController = new StreamController();
    
    /** stream of messages ariving from the remote [CommsEndoint] **/
    Stream get stream => _streamController.stream;
    
    Request._create(CommsEndpoint endpoint, int id) 
            : id = checkNotNull(id)
            , endpoint = checkNotNull(endpoint) {
        
        _streamController.done.then((_) => dispose());
    }
    
    /** 
     * Sends a request to the server. Every sent from the client to the server is tagged with a requestId. 
     * Returns a Stream that will close when a Message marked isFinal=true is received from the server.
     * All server-generated error messages are treated as normal messages by the stream. 
     * For client-side Stream errors, see subclasses of [RequestStreamError]
     * 
     * [requestId]: Used if this [request] is a followup message to an existing conversation. 
     **/
    Stream send(Message message) {
        checkNotNull(message);
        message.json['requestId'] = id;
        if(message.isFinal) {
            dispose();
        }
        endpoint._send(message);
        return stream;
    }
    
    void dispose() {
        endpoint._requests.remove(id);
        _streamController.close();
    }
    
    void _recieve(Message message) {
        
        _streamController.add(message);
        
        if(message.isFinal) {
            dispose();
        }
    }
}


/**
 * Handler for a Request initiated from the far side of this [CommsEndpoint].
 * A [RequestHandler] may remain alive to send and receive multiple messages to and from the remote [CommsEndpoint]. 
 * [RequestHandler] instances areautomatically purged from the local [CommsEndpoint] when they send a message with isFinal = true
 */
abstract class RequestHandler {
    
    final CommsEndpoint endpoint;
    
    /** ID of the [Request] at the remote [CommsEndpoint] that started this conversation **/
    final int requestId;
    
    RequestHandler(CommsEndpoint endpoint, int requestId) 
        : endpoint = checkNotNull(endpoint)
        , requestId = checkNotNull(requestId);
    
    void recieve(Message message);
    
    /** sends a generic, final success message **/
    void sendSuccess([String comment] ) => send(new GenericSuccess(comment));
    
    /** sends a generic, final error message **/
    void sendFail ([String errorMsg]) => send(new GenericFail(errorMsg));
    
    /** Configures the given [response] message as a reply to the given [request] and sends it **/
    void send(Message response, { bool isFinal : true, Result result : null, String comment : null }) {        
        response.json['requestId'] = requestId;
        response.json['isFinal'] = isFinal;
        
        if(result  != null) { response.json['result'] = result;   }
        if(comment != null) { response.json['comment'] = comment; }
        
        if(isFinal) {
            dispose();
        }
        
        endpoint._send(response);
    }
    
    void dispose() {
        endpoint._requestHandlers.remove(requestId);
    }
}

abstract class RequestStreamError { }
class StreamDisposedError   extends RequestStreamError { }
class TimeoutError          extends RequestStreamError { }

