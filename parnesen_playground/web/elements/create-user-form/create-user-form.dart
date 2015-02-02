library playgroundNest;

import 'package:polymer/polymer.dart';
import '../../lib/app/users/user_messages.dart';
import '../../index.dart';
import '../../lib/messaging/messaging.dart';
import '../../lib/collections/collection_messages.dart';


@CustomTag('create-user-form')
class CreateUserForm extends PolymerElement { CreateUserForm.created() : super.created();
    
    @observable String userid;
    @observable String firstname;
    @observable String lastname;
    @observable String role;
    @observable String email;
    @observable String password;
    @observable String reenterpassword;
    
    @observable String output = "";
    
    void create() {
        try {
            User user = new User(userid, firstname, lastname, role, email, unhashedPassword: password);
            if(password != reenterpassword) {
                throw "passwords do not match";
            }
            
            Exchange userExchange = comms.newExchange();
            userExchange.sendRequest(new OpenCollection(userCollectionName, new Filter()))
                .then((Result result) { if (result.isFail) throw "Failed to open UserCollection: $result"; })
                .then((_) => userExchange.sendRequest(new CreateValues([user]), isFinalRequest : true))
                .then((Result result) => output = result.isSuccess ? result.comment : "create failed: ${result}")
                .catchError((error) => output = "!!$error!!");
        }
        catch(error) {
            output = "!!$error!!";
        }
    }
    
}




