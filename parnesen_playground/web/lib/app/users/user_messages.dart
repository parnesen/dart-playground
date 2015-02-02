library user_messages;

import '../../messaging/messaging.dart';
import 'package:quiver/check.dart';

import '../../util.dart';
import '../../sha1_hash.dart';

const String userCollectionName = "UserCollection";

void registerUserMessages() {
    JsonObject.factories.addAll({
        User.NAME                  : (json) => new User.fromJson(json)
    });
}

class User extends JsonObject {
    static const String NAME = "User";
    User.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    User(   String userId, 
            String firstName, 
            String lastName, 
            String role, 
            String email, 
            {
                String hashedPassword, 
                String unhashedPassword,
                bool isAdmin
            }) : super(NAME) {
        
        json['userId']      = checkIsSet(userId, message: "userId is missing");
        json['firstName']   = checkIsSet(firstName, message: "firstName is missing");
        json['lastName']    = checkIsSet(lastName, message: "lastName is missing");
        json['role']        = checkIsSet(role, message: "'role' is missing");
        json['email']       = checkIsEmail(email);
        
        checkState(!(isSet(hashedPassword) && isSet(unhashedPassword)));
        if      (isSet(hashedPassword))   { json['hashedPassword'] = hashedPassword; }
        else if (isSet(unhashedPassword)) { json['hashedPassword'] = sha1Hash[unhashedPassword]; }
        
        if(isAdmin != null) { json['isAdmin'] = isAdmin; }
    }
    
    String get userId       => json['userId'];
    String get firstName    => json['firstName'];
    String get lastName     => json['lastName'];
    String get role         => json['role'];
    String get email        => json['email']; 
    bool   get isAdmin      => true == json['isAdmin'];
    
    /** SHA1 hash of the user's password **/
    @nullable String get hashedPassword => json['hashedPassword'];
}

//The HTML 5 Standard http://stackoverflow.com/questions/16800540/validate-email-address-in-dart
final RegExp emailRegex = new RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");

bool isEmail(String email) => isSet(email) && emailRegex.hasMatch(email);

String checkIsEmail(String email) {
    checkState(isEmail(email), message : "the given string is not a valid email address: '$email'");
    return email;
}