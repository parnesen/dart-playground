library mail_share;

import 'package:quiver/check.dart';

part 'mail_message.dart';
part 'mail_value.dart';


/** instantiates a message of the proper subtype, given the json passed in **/
Message jsonToMessage(Map<String, dynamic> json) {
    checkNotNull(json);
    String name = json["name"];
    checkState(name != null || name.isEmpty, message : "message is missing its name field");
    messageFactory factory = Message.factories[name];
    checkState(factory != null, message : "Missing factory for message $name");
    Message message = factory(json);
    return message;
}

class GenericSuccess extends Message {
    static const String NAME = "GenericSuccess";
    
    GenericSuccess.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    GenericSuccess(Message request, { String comment } ) : super(
            name : NAME, 
            requestId : checkNotNull(request.requestId),
            mailboxId : checkNotNull(request.mailboxId),
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
            mailboxId : checkNotNull(request.mailboxId),
            result : Result.Fail,
            isFinal : true,
            comment : errorMsg);
}