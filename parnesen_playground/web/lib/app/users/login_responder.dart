library login_responder;

import '../../../../lib/db_connection.dart';
import '../../messaging/messaging.dart';
import '../../util.dart';
import '../../sha1_hash.dart';
import 'package:sqljocky/sqljocky.dart';

void registerLoginRequestHandlers() {
    CommsEndpoint.responderFactories.addAll({
        LoginRequest.NAME : (CommsEndpoint endpoint, Message request) => new LoginHandler(endpoint, request.exchangeId),
        LogoutRequest.NAME : (CommsEndpoint endpoint, Message request) => new LogoutHandler(endpoint, request.exchangeId)
    });
}

class LoginHandler extends Responder {

    final Sha1Hash _saltedHash = new Sha1Hash(salt : config['salt']);
    
    LoginHandler(CommsEndpoint endpoint, int exchangeId) : super(endpoint, exchangeId, requiresLogin: false) {
        requests.first.then((LoginRequest request) => authenticate(request));
    }
     
    void authenticate(LoginRequest request) {
        final String userId = request.userId;
        db.startTransaction().then((Transaction transaction) {
            String authenticateSql = "SELECT u.isAdmin, u.lastlogin FROM user u WHERE u.userid = '$userId' AND u.password = '${_saltedHash[request.hashedPassword]}'";
            return transaction.query(authenticateSql)
                .then((Results result) => result.single)
                .then((Row userInfoRow) {
                    String setLastLoginSql = "UPDATE user SET lastLogin='${new DateTime.now().toString()}' WHERE userid = '$userId'";
                    print("sending $setLastLoginSql");
                    return transaction.query(setLastLoginSql)
                        .then((_) => transaction.commit())
                        .then((_) {
                            endpoint.userId     = userId;
                            endpoint.isLoggedIn = true;
                            endpoint.isAdmin    = userInfoRow[0] == 1;
                            DateTime lastLogin = userInfoRow[1];
                            sendResult(request, new LoginSuccess(endpoint.isAdmin, lastLogin));
                        });
                });
        })
        .catchError((error) {
            print(error);
            sendFail(request);
        });        
    }
}

class LogoutHandler extends Responder {
    LogoutHandler(CommsEndpoint endpoint, int exchangeId) : super(endpoint, exchangeId, requiresLogin: false) {
        requests.first.then((LogoutRequest request) {
            endpoint.userId     = null;
            endpoint.isLoggedIn = false;
            endpoint.isAdmin    = false;
            sendSuccess(request);
        });
    }
}