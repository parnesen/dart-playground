library mail_share;

import 'package:quiver/check.dart';

part 'mail_message.dart';

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
    };
    
    /** the underlying json contains all of the message's (and it's subclass') state **/
    final Map<String, dynamic> json;
    
    JsonObject.fromJson(Map<String, dynamic> json) : this.json = json;
}