library user_messages;

import '../../messaging/messaging.dart';
import 'package:quiver/check.dart';

void registerUserMessages() {
    JsonObject.factories.addAll({
        User.NAME                  : (json) => new User.fromJson(json),
        LoginRequest.NAME          : (json) => new LoginRequest.fromJson(json)
    });
}

class User extends JsonObject {
    static const String NAME = "User";
    User.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    User(String userId, String password) : super(NAME) {
        json['userId'] = checkNotNull(userId);
        if(password != null) { json['password'] = password; }
    }
    
    String get userId => json['userId'];
    String get password => json['password'];
}

class LoginRequest extends Message {
    static const String NAME = "Login";
    LoginRequest.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    LoginRequest(String userId, String password) : super(name : NAME) {
        json['userId']   = checkNotNull(userId);
        json['password'] = checkNotNull(password);
    }
    
    String get userId => json['userId'];
    String get password => json['password'];
}

