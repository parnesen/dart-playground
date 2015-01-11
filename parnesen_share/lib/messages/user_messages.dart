library user_messages;

import '../mail/mail_message.dart';
import 'package:quiver/check.dart';

void registerUserMessages() {
    Message.factories.addAll({
        Login.NAME          : (json) => new Login.fromJson(json),
        CreateUser.NAME     : (json) => new CreateUser.fromJson(json),
    });
}

class Login extends Request {
    static final String NAME = "Login";
    Login.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    Login(String userId, String password) : super(NAME) {
        json['userId']   = checkNotNull(userId);
        json['password'] = checkNotNull(password);
    }
    
    String get userId => json['userId'];
    String get password => json['password'];
}

/** server replies with either Success or Fail **/
class CreateUser extends Request {
    static final String NAME = "CreateUser";
    CreateUser.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    CreateUser(String userId, String password) : super(NAME) {
        json['userId']   = checkNotNull(userId);
        json['password'] = checkNotNull(password);
    } 
    
    String get userId => json['userId'];
    String get password => json['password'];
}