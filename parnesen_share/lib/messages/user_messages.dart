library user_messages;

import '../mail/mail_share.dart';
import 'package:quiver/check.dart';

void registerUserMessages() {
    Message.factories.addAll({
        LoginRequest.NAME          : (json) => new LoginRequest.fromJson(json),
        CreateUserRequest.NAME     : (json) => new CreateUserRequest.fromJson(json),
    });
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

/** server replies with either Success or Fail **/
class CreateUserRequest extends Message {
    static const String NAME = "CreateUser";
    CreateUserRequest.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    CreateUserRequest(String userId, String password) : super(name : NAME) {
        json['userId']   = checkNotNull(userId);
        json['password'] = checkNotNull(password);
    }
    
    String get userId => json['userId'];
    String get password => json['password'];
}