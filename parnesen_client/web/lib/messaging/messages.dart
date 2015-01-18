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

abstract class JsonObject {
    
    static final Map<String, jsonObjectFactory> factories = {
          Message.NAME        : (json) => new Message.fromJson(json),
          GenericSuccess.NAME : (json) => new GenericSuccess.fromJson(json),
          GenericFail.NAME    : (json) => new GenericFail.fromJson(json),
          ExchangeEnded.NAME  : (json) => new ExchangeEnded.fromJson(json),
    };
    
    /** the underlying json contains all of the message's (and it's subclass') state **/
    final Map<String, dynamic> json;
    
    JsonObject.fromJson(Map<String, dynamic> json) : this.json = json;
    
    JsonObject(String name) : this.fromJson({
        'name' : checkNotNull(name)
    });
}

class Message extends JsonObject {
    
    static const String NAME = "Message";
    
    Message.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    Message({  String name     : NAME,
               int exchangeId  : null,
               int requestId   : null,
               Result result   : null,
               bool isFinal    : null,
               String comment  : null 
            }) : super(name) {
        
        if(exchangeId != null) { json['exchangeId'] = exchangeId; }
        if(requestId != null) { json['requestId'] = requestId; }
        if(result != null)    { json['result']    = result.value; }
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
    
    /** 
     * Identifies this message as a request, or a reply to a request.
     * Each requestId is unique within the given [Exchange]
     **/
    int get requestId => json['requestId'];
    
    /** indicats the final reply message in a given exchange. **/
    bool get isFinal   => true == json['isFinal'];
    
    /** set by the server on some replies to indicate success or failure in handling the request **/
    Result get result  => Result.valueOf(json[Result.tag]); 
    bool get isSuccess => result == Result.Success;
    bool get isFail    => result == Result.Fail;
    
    /** message dependant, sometimes null **/
    String get comment => json['comment'];
    
    String toString() => json.toString();
}

/** (enum (stored as an int in json)) The result of a request **/
class Result {
    static const String tag = 'result';
    
    static const Result Success = const Result._create(1);
    static const Result Fail = const Result._create(-1);
    static const Result Unspecified = const Result._create(0);
    
    final int value;
    const Result._create(this.value);

    static Result valueOf(int value) {
        if(value == null || value == 0) { return Result.Unspecified; }
        if(value > 0) { return Result.Success; }
        return Result.Fail;
    }
    
    bool get isSuccess      => this == Success;
    bool get isFail         => this == Fail;
    bool get isUnspecified  => this == Unspecified;
}

class GenericSuccess extends Message {
    static const String NAME = "GenericSuccess";
    GenericSuccess.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    GenericSuccess({String comment}) : super(
            name : NAME, 
            result : Result.Success,
            comment : comment);
}

class GenericFail extends Message {
    static const String NAME = "GenericFail";
    
    GenericFail.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    GenericFail({String errorMsg}) : super(
            name : NAME,
            result : Result.Fail,
            comment : errorMsg);
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