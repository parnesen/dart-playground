library playgroundNest;

import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:async';
import '../../index.dart';
import '../../lib/messaging/messaging.dart';
import 'package:quiver/check.dart';

typedef void CancelLoginFunction();

@CustomTag('login-form')
class LoginForm extends PolymerElement { LoginForm.created() : super.created();
    
    @observable String userId;
    @observable String password;
    @observable String output = "";
    
    CancelLoginFunction cancelLoginFunction;
    
    factory LoginForm(CancelLoginFunction cancelLoginFunction) {
        return new Element.tag('login-form') as LoginForm
            ..cancelLoginFunction = checkNotNull(cancelLoginFunction);
    }
    
    StreamSubscription loginSubscription;
    void attached() {
        loginSubscription = comms.initUpdates.listen((_) {
            updateLoginStatus();
        });
        updateLoginStatus();
    }
    
    void updateLoginStatus() {
        output = comms.isLoggedIn ? "logged in" : "logged out";
        userId = comms.userId;
    }
    
    void detached() {
        loginSubscription.cancel();
    }
    
    void login() {
        try {
            LoginRequest request = new LoginRequest(userId, password);
            comms.sendRequest(request)
                .then((Result result) {
                    if(result is LoginSuccess) {
                        output = result.comment;
                        comms.userId = userId;
                        comms.isAdmin = result.isAdmin;
                        comms.isLoggedIn = true;
                    } else {
                        output = "login failed";
                    }
                })
                .catchError((error) => output = "!!$error!!");
        }
        catch(error) {
            output = "!!$error!!";
        }
    }
    
    void logout() {
        comms.sendRequest(new LogoutRequest())
            .then((Result result) {
                if(result.isSuccess) { 
                    comms.isLoggedIn = false;
                    comms.userId = null;
                    comms.isAdmin = false;
                }
                else {
                    output = "Unexpected Error: $result"; 
                }
            });
    }
    
    void cancel() {
        
    }
    
}




