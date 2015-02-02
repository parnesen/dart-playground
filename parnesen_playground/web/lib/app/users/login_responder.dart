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
        db.query("SELECT u.isAdmin FROM user u WHERE u.userid = '${request.userId}' AND u.password = '${_saltedHash[request.hashedPassword]}'" )
            .then((Results result) => result.single)
            .then((Row row) {
                endpoint.userId     = request.userId;
                endpoint.isLoggedIn = true;
                endpoint.isAdmin    = row[0] == 1;
                sendResult(request, new LoginSuccess(endpoint.isAdmin));
            })
            .catchError((error) {
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