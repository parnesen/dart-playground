library mail_share;

import 'package:quiver/check.dart';
import 'dart:convert';

typedef Message messageFactory(Map<String, dynamic> json);

abstract class Message {
    
    static final Map<String, messageFactory> factories = {
        Success.NAME        : (json) => new Success.fromJson(json),
        Fail.NAME           : (json) => new Fail.fromJson(json)                        
    };
    
    /** the underlying json contains all of the message's (and it's subclass') state **/
    final Map<String, dynamic> json;
    
    Message._fromJson(Map<String, dynamic> json) : this.json = json;
    
    Message(String name, { int mailboxId }) : json = {
        'name' : checkNotNull(name),
        'mailboxId' : mailboxId
    };
    
    /** instantiates a message of the proper subtype, given the json passed in **/
    factory Message.fromString(String jsonString) => new Message.fromJson(JSON.decode(jsonString));
    
    /** instantiates a message of the proper subtype, given the json passed in **/
    factory Message.fromJson(Map<String, dynamic> json) {
        checkNotNull(json);
        String name = json["name"];
        checkState(name != null || name.isEmpty, message : "message is missing its name field");
        messageFactory factory = factories[name];
        checkState(factory != null, message : "Missing factory for message $name");
        Message message = factory(json);
        return message;
    }
    
    String get name => json['name'];
    int get mailboxId => json['mailboxId'];
    
    String toString() => json.toString();
}

abstract class Value {
    /** the underlying json contains all of the message's (and it's subclass') state **/
    final Map<String, dynamic> json;
    
    Value.fromJson(Map<String, dynamic> json) : this.json = json;
}

/** A message that expects a reply from the server **/
abstract class Request extends Message {
    Request.fromJson(Map<String, dynamic> json) : super._fromJson(json);
    Request(String name) : super(name);
    
    /** 
     * ties the request back to a future waiting in the client-side mailbox for completion
     * This field is set automatically by the mailbox
     **/
    int get requestId => json['requestId'];
}

/** Replies are sent by the server in reponse to Request messages **/
abstract class Reply extends Message {
    Reply.fromJson(Map<String, dynamic> json) : super._fromJson(json);
    
    Reply(String name, int mailboxId, int requestId, String requestName) : super(name, mailboxId : mailboxId) {
        json['requestId'] = checkNotNull(requestId);
        json['requestName'] = checkNotNull(requestName);
    }
    
    int get requestId => json["requestId"];
    String get requestName => json["requestName"];
}

/** general message sent by the server if a Request is successful */
class Success extends Reply {
    static final String NAME = "Success";
    Success.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    Success.fromRequest(Request request, [String message = ""]) : this(request.mailboxId, request.requestId, request.name, message);
    Success(int mailboxId, int requestId, String requestName, String message) : super(NAME, mailboxId, requestId, requestName) {
        json['message'] = message;
    }
    
    String get message => json['message'];
}

/** a general message sent by the server if a Request is unsuccessful */
class Fail extends Reply {
    static final String NAME = "Fail";
    Fail.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    Fail.fromRequest(Request request, [String errorMessage = ""]) : this(request.mailboxId, request.requestId, request.name, errorMessage);
    Fail(int mailboxId, int requestId, String requestName, String errorMessage) : super(NAME, mailboxId, requestId, requestName) {
        json['errorMessage'] = errorMessage;
    }
    
    String get errorMessage => json['errorMessage'];
}
//
///** server replies with either Success or Fail **/
//class Login extends Request {
//    static final String NAME = "Login";
//    Login.fromJson(Map<String, dynamic> json) : super.fromJson(json);
//    
//    Login(String userId, String password) : super(NAME) {
//        json['userId']   = checkNotNull(userId);
//        json['password'] = checkNotNull(password);
//    }
//    
//    String get userId => json['userId'];
//    String get password => json['password'];
//}
//
///** server replies with either Success or Fail **/
//class CreateUser extends Request {
//    static final String NAME = "CreateUser";
//    CreateUser.fromJson(Map<String, dynamic> json) : super.fromJson(json);
//    
//    CreateUser(String userId, String password) : super(NAME) {
//        json['userId']   = checkNotNull(userId);
//        json['password'] = checkNotNull(password);
//    } 
//    
//    String get userId => json['userId'];
//    String get password => json['password'];
//}
//
//class CreatePost extends Request {
//    static final String NAME = "CreatePost";
//    
//    final Post post;
//    
//    CreatePost.fromJson(Map<String, dynamic> json) : 
//        super.fromJson(json), 
//        post = new Post.fromJson(checkNotNull(json['post']));
//    
//    CreatePost(Post post) : super(NAME), post = post {
//        json['post'] = post.json;
//    }
//}
//
//class Post extends Value {
//    
//    Post.fromJson(Map<String, dynamic> json) : super.fromJson(json);
//    
//    Post(String userId, String text, {bool isImportant : false, bool isTask : false, bool isStrikethrough : false}) : this.fromJson({
//        'userId' : checkNotNull(userId),
//        'text' : text != null ? text : "",
//        'isImporant' : isImportant,
//        'isTask' : isTask,
//        'isStrikethrough' : isStrikethrough,
//    });
//    
//    String get userId           => json['userId'];
//    String get text             => json['text'];
//    bool   get isImportant      => json['isImportant'];
//    bool   get isTask           => json['isTask'];
//    bool   get isStrikethrough  => json['isStrikethrough'];
//}

