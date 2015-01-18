part of messaging;

/**
 * A simple model for asynchronous communication between client and server via websockets, sending and receiving json-backed Dart Objects.
 * All json values sent and received must be maps.
 * 
 * The idea is to have one CommsEndpoint at each client, and in the server, a CommsEndpoint for each connected client. 
 *  
 * The CommsEndpoint pipe is symmetical: Both the client or the server may 
 * initiate a [Request] for its counterparty to handle (with a [Responder]). 
 * 
 * a [Request] may constitute a simple single-request/single-reply, or the client and server may both send
 * multiple messages over the lifespan of the [Request]. 
 * 
 * @author parnesen
 */

typedef void Sender(String message);

final Logger log = new Logger('CommsEndpoint');

typedef Responder ResponderFactory(CommsEndpoint endpoint, Message request);

class CommsEndpoint {
    
    static final Map<String, ResponderFactory> responderFactories = {};
    
    final bool isClientSide;
    bool get   isServerSide => !isClientSide;
    
    /** the function this [CommsEndpoint] calls to send a string to its remote counterpart **/
    final Sender _senderFunction;
    
    /** open conversations between this endpoint and the remote endpoint**/
    final Map<int, Exchange> _exchanges = {};

    /** 
     *  if [side] is Client then the id of the first request initiated on this side will be 1 and subsequent ids will be > 
     *  if [side] is Server then the id of the first request initiated on this side will be -1 and subsequent ids will be <
     */
    int _exchangeCounter = 0;
    int _lastResponderId = 0;
    
    CommsEndpoint.clientSide(Sender sendFunction)
        : isClientSide = true
        , _senderFunction = checkNotNull(sendFunction);
    
    CommsEndpoint.serverSide(Sender sendFunction)
        : isClientSide = false
        , _senderFunction = checkNotNull(sendFunction);
    
    /** 
     * sends a single request to the remote [CommsEndpoint] and returns a future for the single expected reply.
     * Use this method for simple single-request/single-reply interop. 
     * 
     * For more complex client-server interop use the [newExchange] method to create
     * a [Exchange] object through which multiple messages can be sent or received.
     **/
    Future<Message> send(Message message) => newExchange().sendRequest(message);    
    
    Exchange newExchange() {
        int exchangeId = isClientSide ? ++_exchangeCounter : --_exchangeCounter;
        Exchange exchange = new Exchange._create(this, exchangeId);
        _exchanges[exchangeId] = exchange;
        return exchange;
    }
    
    bool isExchangeOriginatedHere(int exchangeId) => isClientSide ? exchangeId > 0 : exchangeId < 0;    
    
    String toString() => "CommsEndpoint[${isClientSide ? "ClientSide" : "ServerSide"}]";    

    /** Incomming traffic from the remote Endpoint goes here **/
    void receive(String jsonString) {
        Message message;
        try {
            message = jsonToObj(JSON.decode(jsonString));
        }
        catch(error) {
            log.warning("Unable to parse string as Message: '$jsonString' due to error $error");
            return;
        }
        
        log.info("Recieved Message : $message");
        
        int exchangeId = message.exchangeId;
        
        void onError(String errorMsg) {
            log.warning(errorMsg);
            _send(  new GenericFail(errorMsg : errorMsg), 
                    exchangeId  : message.exchangeId, 
                    requestId   : message.requestId,
                    isFinal     : true); 
        }
             
        _forwardMessageToExchange(exchangeId, message, onError);
    }

    void _forwardMessageToExchange(int exchangeId, Message message, void onError(String errorMessage)) {
        Exchange exchange = _exchanges[exchangeId];
        if(exchange == null) {
            if(isExchangeOriginatedHere(exchangeId) || exchangeId <= _lastResponderId) {
                  onError("$this recieved a message for which the Exchange has expired: ${message.name}");
                  return;
            }
            else {
                _lastResponderId = exchangeId;
                ResponderFactory factory = responderFactories[message.name];
                if(factory == null) {
                    onError("$this: No ResponderFactory registered for message of type ${message.name}");                   
                    return;
                }
                exchange = factory(this, message);
                _exchanges[exchangeId] = exchange;
            }
        }
      
        exchange._recieve(message);
    }
    
    /** Internal method used by [Request] and [Responder] to send fully prepared messages to the remote [CommsEndpoint]**/
    void _send(Message message, {
                   String name,
                   int exchangeId,
                   int requestId,
                   Result result,
                   bool isFinal,
                   String comment 
        }) {
            if(name         != null) { message.json['name']         = name;         }
            if(exchangeId   != null) { message.json['exchangeId']   = exchangeId;   }
            if(requestId    != null) { message.json['requestId']    = requestId;    }
            if(result       != null) { message.json['result']       = result;       }
            if(isFinal      != null) { message.json['isFinal']      = isFinal;      }
            if(comment      != null) { message.json['name']         = comment;      }
        
            log.info("Sending Message $message");
            //print("Sending Message $message");
            checkState(message.exchangeId != null);
            String str = JSON.encode(message.json); 
            _senderFunction(str);
    }
}

/**
 * An Exchange represents a conversation between two endoints. When a conversation begins, an Exchange is instantiated 
 * for each endpoint. The Exchange represents the converstion and provides the conversation with context. 
 */
class Exchange {
    final CommsEndpoint endpoint;
    final int exchangeId;
    final StreamController<Message> _streamController = new StreamController.broadcast();
    
    bool  _isOpen = true;
    bool get isOpen => _isOpen;
    bool _isFinalMessageSentOrReceived = false;
    int _requestCounter = 0;
    
    /** stream of messages ariving from the remote [CommsEndoint] **/
    Stream<Message> get stream => _streamController.stream;
    
    StreamController<Request> _requestController;
    
    Stream<Request> get requests {
        if(_requestController == null) {
            _requestController = new StreamController.broadcast();
            StreamSubscription subscription = stream
                .where(  (Message message) => message.requestId != null && !isRequestOriginatedHere(message.requestId))
                .listen( (Message message) => _requestController.add(new Request._create(this, message)));
            
            _requestController.done.then((_) => subscription.cancel());
        }
        return _requestController.stream;
    }
    
    final Completer<Responder> _onClose = new Completer();
    Future<Responder> get onClose => _onClose.future;
    
    bool isRequestOriginatedHere(int requestId) => endpoint.isClientSide ? requestId > 0 : requestId < 0;
    
    Exchange._create(CommsEndpoint endpoint, int exchangeId) 
            : exchangeId = checkNotNull(exchangeId)
            , endpoint = checkNotNull(endpoint) {
        
        _streamController.done.then((_) => dispose());
    }
    
    /** creates a new requestId that's unique within this exchange **/
    int nextRequest() => endpoint.isClientSide ? ++_requestCounter : --_requestCounter;
    
    /** Sends a request and yields afuture that completes when the reply returns **/
    Future<Message> sendRequest(Message request) {
        final int requestId = nextRequest();
        return send(request, requestId : requestId)
                .firstWhere((Message message) => message.requestId == requestId);
    }
    
    Stream send(Message message, { int requestId, bool isFinal, String comment }) {
        endpoint._send( message, 
                        requestId : requestId,
                        exchangeId : exchangeId,
                        isFinal : isFinal, 
                        comment : comment);
        
        if(message.isFinal) {
            _isFinalMessageSentOrReceived = true;
            dispose();
        }
        return stream;
    }
    
    void dispose() {
        if(!_isOpen) { return; }
        
        _isOpen = false;
        if(!_isFinalMessageSentOrReceived) {
            try {
                endpoint._send(new ExchangeEnded(exchangeId));
            } catch(error) { log.warning("Unable to send RequestEnded message: $error"); }
            _isFinalMessageSentOrReceived = true;
        }
        endpoint._exchanges.remove(exchangeId);
        _streamController.close();
        _onClose.complete(this);
    }
    
    void _recieve(Message message) {
        _streamController.add(message);
        if(message.isFinal) {
            _isFinalMessageSentOrReceived = true;
            dispose();
        }
    }
    
}

/**
 * An [Exchange] that responds to requests initiated from the remote [CommsEndpoint].
 * A [Responder] may remain alive to send and receive multiple messages to and from the remote [Exchange]. 
 * [Responder] instances areautomatically purged from the local [CommsEndpoint] when they send a message with isFinal = true
 */
abstract class Responder extends Exchange {
    
    /** true when this requestHandler sends a single reply (which then gets automatically marked with isFinal = true) **/
    final bool isSingleReply;
        
    Responder(CommsEndpoint endpoint, int exchangeId, {isSingleReply : true}) 
        : super._create(endpoint, exchangeId)
        , isSingleReply = isSingleReply;
    
    /** Configures the given [response] message as a reply and sends it **/
    Stream send(Message response, { int requestId, bool isFinal, Result result : null, String comment : null }) {        
        isFinal = isFinal != null ? isFinal : isSingleReply;
        if(requestId != null) { response.json['requestId'] = requestId; }
        if(result != null) { response.json['result'] = result; }
        if(response.result != null && response.result.isFail && response.comment != null) {
            log.warning("Sending failure message: ${response.comment}");
        }
        return super.send(response, isFinal : isFinal, comment : comment);
    }
}

/** represents a request initiated by the remote [Exchange]. [Responder] offers a stream of them. **/
class Request<M extends Message> {
    final Responder responder;
    final M message;
    int get requestId => message.requestId;
    
    Request._create(this.responder, this.message);
    
    /** sends a generic, success message **/
    void sendSuccess({String comment, bool isFinal }) { 
        send(new GenericSuccess(comment : comment), isFinal : isFinal); 
    } 
    
    /** sends a generic, final error message **/
    void sendFail ({String errorMsg, bool isFinal }) {
        send(new GenericFail(errorMsg : errorMsg), isFinal : isFinal);
    }
    
    /** Configures the given [response] message as a reply and sends it **/
    void send(Message response, { bool isFinal, Result result, String comment }) {     
        responder.send(response, requestId : requestId, isFinal : isFinal, result : result, comment : comment);
    }
}

abstract class ExchangeStreamError { }
class StreamDisposedError   extends ExchangeStreamError { }
class TimeoutError          extends ExchangeStreamError { }

