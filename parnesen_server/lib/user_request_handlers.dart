library user_request_handlers.dart;

import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'package:parnesen_share/mail/comms_endpoint.dart';
import 'package:parnesen_share/mail/mail_share.dart';
import 'package:parnesen_share/messages/user_messages.dart';
import 'db_connection.dart';

final Logger log = new Logger('user_request_handlers');

void registerUserRequestHandlers() {
    CommsEndpoint.requestHandlerFactories.addAll({
        CreateUserRequest.NAME: (CommsEndpoint endpoint, Message request) => new CreateUserHandler(endpoint, request.requestId)
    });
}


class CreateUserHandler extends RequestHandler {
    CreateUserHandler(CommsEndpoint endpoint, int requestId) : super(endpoint, requestId);
    
    void recieve(CreateUserRequest request) {
        String sql =    "INSERT INTO user(userid, password)"
                        "VALUES('${request.userId}', '${request.password}')";
             
        db.query(sql)
            .then((_) => sendSuccess("user ${request.userId} created"))
            .catchError((e) {
                String msg = "create user failed: $e";
                log.warning(msg);
                sendFail(msg);
            });
    }
}
