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
    DateTime prevSessionLogin;
    
    factory LoginForm(CancelLoginFunction cancelLoginFunction) {
        return new Element.tag('login-form') as LoginForm
            ..cancelLoginFunction = checkNotNull(cancelLoginFunction);
    }
    
    StreamSubscription loginSubscription;
    void attached() {
        super.attached();
        loginSubscription = comms.initUpdates.listen((_) {
            updateLoginStatus();
        });
        updateLoginStatus();
    }
    
    void updateLoginStatus() {
        String prevLogin = prevSessionLogin != null ? ", previous login was at ${prevSessionLogin}" : "";
        output = comms.isLoggedIn ? "logged in as ${comms.userId}$prevLogin" : "logged out";
        print(output);
        userId = comms.userId != null ? comms.userId : userId;
    }
    
    void detached() {
        super.detached();
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
                        this.prevSessionLogin = result.lastLogin;
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




