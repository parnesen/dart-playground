part of mail_share;


class Message extends JsonObject {
    
    static const String NAME = "Message";
    
    Message.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    Message({  String name     : NAME,
               int requestId   : null,
               Result result   : null,
               bool isFinal    : null,
               String comment  : null 
            }) : super.fromJson({}) {
        
        json['name'] = checkNotNull(name);
        
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
    
    /** 
     * Set by the client on requests if it expects a reply. 
     * Set by the server on replies to route replies back to the correct client-side reply-handler 
     */
    int  get requestId => json['requestId'];
    
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
}

class GenericSuccess extends Message {
    static const String NAME = "GenericSuccess";
    
    GenericSuccess.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    GenericSuccess(Message request, { String comment } ) : super(
            name : NAME, 
            requestId : checkNotNull(request.requestId),
            result : Result.Success,
            isFinal : true,
            comment : comment);
}

class GenericFail extends Message {
    static const String NAME = "GenericFail";
    
    GenericFail.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    GenericFail(Message request, { String errorMsg } ) : super(
            name : NAME, 
            requestId : checkNotNull(request.requestId),
            result : Result.Fail,
            isFinal : true,
            comment : errorMsg);
}