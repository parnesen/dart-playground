part of messaging;

/**
 * A framework for asynchronous communication between client and server via websockets, sending and receiving json-backed Dart Objects.
 * 
 * The idea is to have one CommsEndpoint inside each browser, and in the server, a CommsEndpoint for each connected browser. 
 *  
 * The CommsEndpoint pipe is symmetical: Both the client or the server may open a new [Exchange]
 * and initiate a [Request] for its counterparty to handle (with a [Responder]). 
 * 
 * A communication between two CommsEndpoints always takes place within the context of an [Exchange], which represents a unique conversation
 * between the two [CommsEndpoint]s.
 * 
 * A [Responder] is an [Exchange] that is spawned by the [CommsEndpoint] receving a new [Request] message.
 * 
 * An [Exchange] may constitute a simple single-request/single-reply, or the client and server may both send
 * multiple messages over the lifespan of the [Exchange].
 * 
 * A [Request] is always responded to with a single [Result]. Once opened, a [Responder] may elect to stick around
 * to handle more [Request]s on the same exchange.
 * 
 * To end an [Exchange], send a message with the isFinal flag set to true. This will cause both the sending and the receiving
 * [Exchange] to dispose. You can also send a [Request] with the isFinalRequest flag set to true. This will cause the server 
 * to send its [Result] with the isFinal flag set to true.
 * 
 * @author parnesen
 */

typedef void SendFunction(String message);

final Logger log = new Logger('CommsEndpoint');

typedef Responder ResponderFactory(CommsEndpoint endpoint, Request request);

class CommsEndpoint {
    
    static final Map<String, ResponderFactory> responderFactories = {};
    
    final bool isClientSide;
    bool get   isServerSide => !isClientSide;
    
    @nullable String userId;
    
    bool _isLoggedIn = false;
    bool get isLoggedIn => _isLoggedIn;
    void set isLoggedIn(bool val) {
        if(_isLoggedIn == checkNotNull(val)) { return; }
        _isLoggedIn = val;
        _loginStreamController.add(val);
        if(_isLoggedIn) {
            _whenLoggedOutCompleter = new Completer();
            _whenLoggedInCompleter.complete();
        }
        else {
            _whenLoggedOutCompleter.complete();
            _whenLoggedInCompleter = new Completer();
        }
    }
    
    Completer _whenLoggedInCompleter  = new Completer();
    Completer _whenLoggedOutCompleter = new Completer()..complete();
    Future get whenLoggedIn  => _whenLoggedInCompleter.future;
    Future get whenLoggedOut => _whenLoggedOutCompleter.future;
    final StreamController<bool> _loginStreamController = new StreamController.broadcast();
    Stream<bool> get loginStream => _loginStreamController.stream;
    
    
    bool isAdmin;
    
    /** attributes this [CommsEndpoint] or the user it represents */
    final Map<String, dynamic> attributes = {};
    
    /** the function this [CommsEndpoint] calls to send a string to its remote counterpart **/
    final SendFunction _senderFunction;
    
    /** open conversations between this endpoint and the remote endpoint**/
    final Map<int, Exchange> _exchanges = {};

    /** 
     *  if [side] is Client then the id of the first request initiated on this side will be 1 and subsequent ids will be > 
     *  if [side] is Server then the id of the first request initiated on this side will be -1 and subsequent ids will be <
     */
    int _exchangeCounter = 0;
    
    CommsEndpoint.clientSide(SendFunction sendFunction)
        : isClientSide = true
        , _senderFunction = checkNotNull(sendFunction);
    
    CommsEndpoint.serverSide(SendFunction sendFunction)
        : isClientSide = false
        , _senderFunction = checkNotNull(sendFunction);
    
    /** 
     * sends a single request to the remote [CommsEndpoint] and returns a future for the single expected reply.
     * Use this method for simple single-request/single-reply interop. 
     * 
     * For more complex client-server interop use the [newExchange] method to create
     * an [Exchange] object through which multiple [Message]s [Request]s and [Result]s can be sent or received.
     **/
    Future<Message> sendRequest(Message message) => newExchange().sendRequest(message, isFinalRequest: true);    
    
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
            log.info("Recieved ${messageTypeOf(message)} : $message");
        }
        catch(error) {
            log.warning("Unable to parse string as Message: '$jsonString' due to error $error");
            return;
        }
        
        try {  
            _forwardMessageToExchange(message);
        }
        catch(error, stacktrace) {
            log.warning("Error handling message $message", error, stacktrace);
        }
    }

    void _forwardMessageToExchange(final Message message) {
        
        final int exchangeId = message.exchangeId;
        
        final Exchange exchange = _exchanges[exchangeId];
        if(exchange != null) {
            exchange._recieve(message);
            return;
        }
        
        if(isExchangeOriginatedHere(exchangeId)) {
            if(!(message is ExpiredExchange)) {
                _send(new ExpiredExchange(message.exchangeId));
            }
            return;
        }
        
        if((message is Request)) {
            handleNewRequest(message);
        }
        else {
            log.warning("A message was received for which there is no registered exchange: $message");
        }
    }

    void handleNewRequest(final Request request) {
        ResponderFactory factory = responderFactories[request.name];
        if(factory == null) {
            String errorMsg = "$this: No ResponderFactory registered for request of type ${request.name}";
            log.warning(errorMsg);
            _send(  new GenericFail(requestId: request.requestId, errorMsg : errorMsg), 
                    exchangeId  : request.exchangeId,  
                    isFinal     : true);                                       
            return;
        }
      
        Responder responder = factory(this, request);
        _exchanges[request.exchangeId] = responder;
      
        responder._recieve(request);
    }
    
    /** Internal method used by [Request] and [Responder] to send fully prepared messages to the remote [CommsEndpoint]**/
    void _send(Message message, {
                   String name,
                   int exchangeId,
                   bool isFinal,
                   String comment 
        }) {
            if(name         != null) { message.json['name']         = name;         }
            if(exchangeId   != null) { message.json['exchangeId']   = exchangeId;   }
            if(isFinal      != null) { message.json['isFinal']      = isFinal;      }
            if(comment      != null) { message.json['name']         = comment;      }
        
            log.info("Sending ${messageTypeOf(message)} : $message");
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
                .where  ((Message message) => message is Request && !isRequestOriginatedHere(message.requestId))
                .listen ((Message message) => _requestController.add(message as Request));
            
            _requestController.done.then((_) {
                subscription.cancel();
                _requestController = null;
            });
        }
        return _requestController.stream;
    }
    
    final Completer<Responder> _onClose = new Completer();
    Future<Responder> get onClose => _onClose.future;
    
    bool isRequestOriginatedHere(int requestId) => endpoint.isClientSide ? requestId > 0 : requestId < 0;
    
    Exchange._create(CommsEndpoint endpoint, int exchangeId) 
            : exchangeId = checkNotNull(exchangeId)
            , endpoint = checkNotNull(endpoint) {
        log.info("Exchange $exchangeId created ");
        _streamController.done.then((_) => dispose());
    }
    
    /** creates a new requestId that's unique within this exchange **/
    int nextRequest() => endpoint.isClientSide ? ++_requestCounter : --_requestCounter;
    
    /** Sends a request and yields a future that completes when the reply returns **/
    Future<Result> sendRequest(Request request, {bool isFinalRequest}) {
        final int requestId = nextRequest();
        if(isFinalRequest != null) { request.json['isFinalRequest'] = isFinalRequest; }
        request.json['requestId'] = requestId;
        return send(request).firstWhere((Message message) => message is Result && message.requestId == requestId);
    }
    
    Stream<Message> send(Message message, { bool isFinal, String comment }) {
        if(!isOpen) {
            String errorMsg = "Exchange[$exchangeId] is closed and cannot send message $message";
            log.warning(errorMsg);
            throw new StateError(errorMsg);
        }
        
        checkState(isOpen, message : "Exchange[$exchangeId] is closed and cannot send message $message");
        endpoint._send( message,
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
        log.info("Exchange $exchangeId disposed");
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
 * [Responder] instances are automatically purged from the local [CommsEndpoint] when they send a message with isFinal = true
 * 
 * Concrete instances should handle requests off of the [requests] stream of the [Exchange] baseclass
 * 
 * A responder can be flagged as [requiresLogin] or [requiresAdminStatus], which when true, will prevent [Requests]
 * from reaching the responder if the required state isn't met. The [CommmEndpoint] then automatically sends 
 * [RequiresLogin] or [RequiresAdminStatus] results back to the client.
 */
abstract class Responder extends Exchange {
    
    /** 
     * true by default.
     * true when this requestHandler sends a single reply (which then gets automatically marked with isFinal = true).
     */
    final bool isSingleReply;
    
    /** 
     * true by default. 
     * only affects server-side responders. When true, the responder will not receive the Request unless the user is logged in 
     **/
    final bool requiresLogin;
    
    /** 
     * false by default. 
     * only affects server-side responders. When true, the responder will not receive the Request unless the user is an admin 
     **/
    final bool requiresAdminStatus;
        
    Responder(CommsEndpoint endpoint, int exchangeId, {isSingleReply : true, bool requiresLogin : true, bool requiresAdminStatus : false}) 
        : super._create(endpoint, exchangeId)
        , isSingleReply = isSingleReply
        , requiresLogin = requiresLogin == true
        , requiresAdminStatus = requiresAdminStatus == true;
    
    void _recieve(Message message) {
        void sendError(Message error) {
            if(message is Request) { sendResult(message, error); }
            else { send(error); }
        }
        
        if(endpoint.isClientSide) {
            super._recieve(message);
        }
        else if(requiresLogin && !endpoint.isLoggedIn) {
            sendError(new UserNotLoggedIn());
        }
        else if(requiresAdminStatus && !endpoint.isAdmin) {
            sendError(new UserNotAdmin());
        }
        else {
            super._recieve(message);
        }
    }
    
    /** sends a generic, success message **/
    void sendSuccess(Request request, {String comment}) => sendResult(request, new GenericSuccess(comment : comment)); 
    
    /** sends a generic, final error message **/
    void sendFail (Request request, {String errorMsg}) => sendResult(request, new GenericFail(errorMsg : errorMsg));
    
    /** Configures the given [response] message as a reply and sends it **/
    void sendResult(Request request, Result result, { String comment, bool isFinal }) {
        result.json['requestId'] = request.requestId;
        
        isFinal = isFinal == true || request.isFinalRequest == true;
        send(result, isFinal : isFinal, comment : comment);
    }
    
    /** Configures the given [message] message as a reply and sends it **/
    Stream<Message> send(Message message, { bool isFinal, String comment : null }) {        
        isFinal = isFinal == true || isSingleReply == true;
        if(message is Result && message.isFail && message.comment != null) {
            log.warning("Sending failure result: ${message.comment}");
        }
        return super.send(message, isFinal : isFinal, comment : comment);
    }    
}

abstract class ExchangeStreamError { }
class StreamDisposedError   extends ExchangeStreamError { }
class TimeoutError          extends ExchangeStreamError { }
