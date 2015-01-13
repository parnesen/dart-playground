part of mail_share;

typedef Message messageFactory(Map<String, dynamic> json);

class Message {
    
    static const String NAME = "Message";
    
    static final Map<String, messageFactory> factories = {
          Message.NAME        : (json) => new Message.fromJson(json),
          GenericSuccess.NAME : (json) => new GenericSuccess.fromJson(json),
          GenericFail.NAME    : (json) => new GenericFail.fromJson(json),
    };
    
    /** the underlying json contains all of the message's (and it's subclass') state */
    final Map<String, dynamic> json;
    
    Message.fromJson(Map<String, dynamic> json) : this.json = json;
    
    Message({  String name     : NAME,
               int mailboxId   : null, 
               int requestId   : null,
               Result result   : null,
               bool isFinal    : null,
               String comment  : null 
            }) : json = {} {
        
        json['name'] = checkNotNull(name);
        if(mailboxId != null) { json['mailboxId'] = mailboxId; }
        if(requestId != null) { 
            checkState(mailboxId != null, message : "'requestId' cannot be specified without a mailboxId");
            json['requestId'] = requestId; 
        }
        if(result != null)    { 
            checkState(requestId != null, message : "'result' cannot be specified without a mailboxId");
            json['result']    = result.value; 
        }
        if(isFinal != null)   { json['isFinal']   = isFinal; }
        if(comment != null)   { json['comment']   = comment; }
    }
    
    /** 
     * This uniquly names each type of Message. Name should be Message.NAME for untyped messages or the name of a concrete subclass of Message 
     * The name maps to a factory function used to deserialize a Message from json.
     */
    String get name => json['name'];
    
    /** the mailboxId of the client-side requestor */
    int get mailboxId => json['mailboxId'];
    
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