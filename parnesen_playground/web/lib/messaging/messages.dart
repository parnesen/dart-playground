part of messaging;

typedef JsonObject jsonObjectFactory(Map<String, dynamic> json);

/** instantiates a message of the proper subtype, given the json passed in **/
JsonObject jsonToObj(Map<String, dynamic> json) {
    checkNotNull(json);
    String name = json["name"];
    checkState(name != null || name.isEmpty, message : "message is missing its name field");
    jsonObjectFactory factory = JsonObject.factories[name];
    checkState(factory != null, message : "Missing factory for message $name");
    JsonObject obj = factory(json);
    return obj;
}

/** Base class for [Message]s and for json-backed objects contained by [Message]s **/
abstract class JsonObject {
    
    static final Map<String, jsonObjectFactory> factories = {
          Message.NAME          : (json) => new Message.fromJson(json),
          Result.NAME           : (json) => new GenericSuccess.fromJson(json),
          GenericSuccess.NAME   : (json) => new GenericSuccess.fromJson(json),
          GenericFail.NAME      : (json) => new GenericFail.fromJson(json),
          ExchangeEnded.NAME    : (json) => new ExchangeEnded.fromJson(json),
          ExpiredExchange.NAME  : (json) => new ExpiredExchange.fromJson(json),
          LoginRequest.NAME     : (json) => new LoginRequest.fromJson(json),
          LogoutRequest.NAME    : (json) => new LogoutRequest.fromJson(json),
          LoginSuccess.NAME     : (json) => new LoginSuccess.fromJson(json),
          UserNotLoggedIn.NAME  : (json) => new UserNotLoggedIn.fromJson(json),
          UserNotAdmin.NAME     : (json) => new UserNotAdmin.fromJson(json),          
    };
    
    /** the underlying json contains all of the message's (and it's subclass') state **/
    final Map<String, dynamic> json;
    
    JsonObject.fromJson(Map<String, dynamic> json) : this.json = json;
    
    JsonObject(String name) : this.fromJson({
        'name' : checkNotNull(name)
    });
}

/** A message sent by an [Exchange] via a [CommsEndpoint] **/
class Message extends JsonObject {
    
    static const String NAME = "Message";
    
    Message.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    Message({  String name     : NAME,
               int exchangeId  : null,
               int requestId   : null,
               bool isFinal    : null,
               String comment  : null 
            }) : super(name) {
        
        if(exchangeId != null) { json['exchangeId'] = exchangeId; }
        if(isFinal != null)   { json['isFinal']   = isFinal; }
        if(comment != null)   { json['comment']   = comment; }
    }
    
    /** 
     * This uniquly names each type of Message. Name should be Message.NAME for untyped messages or the name of a concrete subclass of Message 
     * The name maps to a factory function used to deserialize a Message from json.
     */
    String get name => json['name'];
    
    /** The exchange that this message is a part of **/
    int  get exchangeId => json['exchangeId'];
    
    /** true if this the final message in a given exchange and that [Exchange] that sent has been or soon will be torn down **/
    bool get isFinal => true == json['isFinal'];
    
    /** message dependant, sometimes null **/
    String get comment => json['comment'];
    
    String toString() => json.toString();
}

/** an [Exchange] sends a [Request] to the remote endpoint and expects a [Result] in reply **/
abstract class Request extends Message {
    static const String NAME = "Request";
    
    Request.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    Request({   String name     : NAME,
                int exchangeId,
                int requestId,
                bool isFinalRequest,
                String comment 
     }) : super(name : name != null ? name : NAME, exchangeId : exchangeId, comment : comment) {
        
        if(requestId != null)      { json['requestId'] = requestId; }
        if(isFinalRequest != null) { json['isFinalRequest'] = requestId; }
    }
    
    int get requestId      => json['requestId'];
    
    /** True if this is the final request in the exchange, and the remote [Responder] may be torn down after answering it. **/
    bool get isFinalRequest => json['isFinalRequest'];
}

/** The reply to a given [Request] **/
class Result extends Message {
    static const String NAME = "Result";
    
    Result.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    Result(   { String name     : NAME,
                int exchangeId,
                int requestId,
                bool isFinal,
                String comment,
                bool isSuccess
     }) : super(name : name != null ? name : NAME, exchangeId : exchangeId, isFinal : isFinal, comment : comment) {
        
        if(requestId != null) json['requestId'] = requestId;
        if(isSuccess != null) json['isSuccess'] = isSuccess;
    }
    
    int  get requestId => json['requestId'];
    bool get isSuccess => json['isSuccess'];
    bool get isFail    => isSuccess == false;
}

/** a message that can be returned by a Responder to indicate a successful operation **/
class GenericSuccess extends Result {
    static const String NAME = "GenericSuccess";
    GenericSuccess.fromJson(Map<String, dynamic> json) : super.fromJson(json);    
    GenericSuccess({int requestId, String comment}) : super(name: NAME, requestId: requestId, isSuccess: true, comment: comment);
}

/** a message that can be returned by a Responder to indicate a failure **/
class GenericFail extends Result {
    static const String NAME = "GenericFail"; 
    GenericFail.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    GenericFail({int requestId, String errorMsg}) : super(name: NAME, requestId: requestId, isSuccess: false, comment: errorMsg);
}

/** a message sent out in response to a received message for an [Exchange] that is no longer open **/
class ExpiredExchange extends Message {
    static const String NAME = "ExpiredExchange";
    
    ExpiredExchange.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    ExpiredExchange(int exchangeId) : super(
            name : NAME,
            isFinal : true,
            exchangeId : exchangeId,
            comment : "This Exchange has expired");
}

/** 
 * Sent to end an [Exchange]. Use this only if there is not other message that can be sent as part of the conversation with the isFinal=true
 * flag set to true.
 */
class ExchangeEnded extends Message {
    static const String NAME = "ExchangeEnded";
    ExchangeEnded.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    ExchangeEnded(int exchangeId) : super(name : NAME, isFinal : true, exchangeId : checkNotNull(exchangeId));
}

String messageTypeOf(Message message) {
    if(message is Request) { return "Request"; }
    if(message is Result)  { return "Result";  }
    return "Message";
}

void registerLoginMessages() {
    JsonObject.factories.addAll({
        LoginRequest.NAME          : (json) => new LoginRequest.fromJson(json),
        LogoutRequest.NAME         : (json) => new LogoutRequest.fromJson(json),
        LoginSuccess.NAME          : (json) => new LoginSuccess.fromJson(json),
        UserNotLoggedIn.NAME       : (json) => new UserNotLoggedIn.fromJson(json),
        UserNotAdmin.NAME          : (json) => new UserNotAdmin.fromJson(json),
    });
}

class LoginRequest extends Request {
    static const String NAME = "Login";
    LoginRequest.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    LoginRequest(String userId, String password) : super(name : NAME) {
        json['userId']   = checkNotNull(userId);
        json['hashedPassword'] = sha1Hash[checkIsSet(password)];
    }
    
    String get userId => json['userId'];
    String get hashedPassword => json['hashedPassword'];
}

class LogoutRequest extends Request {
    static const String NAME = "Logout";
    LogoutRequest.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    LogoutRequest() : super(name : NAME);
}

class LoginSuccess extends Result {
    static const String NAME = "LoginSuccess";
    LoginSuccess.fromJson(Map<String, dynamic> json) : super.fromJson(json);
     
    LoginSuccess(bool isAdmin, DateTime lastLogin) : super(name : NAME) {
        json['isAdmin'] = isAdmin;
        json['lastLogin'] = lastLogin.toString();
    }
    
    bool get isAdmin => json['isAdmin'];
    DateTime get lastLogin => DateTime.parse(json['lastLogin']);
}

/** sent by the server if the client attempts a [Request] before logging in */
class UserNotLoggedIn extends Result {
    static const String NAME = "UserNotLoggedIn";
    UserNotLoggedIn.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    UserNotLoggedIn() : super(name : NAME, isSuccess : false);
}

/** sent by the server if a non-admin client attempts a [Request] for which admin privileges are required */
class UserNotAdmin extends Result {
    static const String NAME = "UserNotAdmin";
    UserNotAdmin.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    UserNotAdmin() : super(name : NAME, isSuccess : false, isFinal : true);
}