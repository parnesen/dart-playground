library user_request_handlers.dart;

import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'package:parnesen_share/mail/comms_endpoint.dart';
import 'package:parnesen_share/mail/mail_share.dart';
import 'package:parnesen_share/messages/user_messages.dart';
import 'db_connection.dart';

final Logger log = new Logger('user_request_handlers');

void registerUserRequestHandlers() {
    CommsEndpoint.requestHandlerFactories.addAll({
        CreateUserRequest.NAME: CreateUserHandler.factory
    });
}


class CreateUserHandler extends RequestHandler {
    static CreateUserHandler factory(CommsEndpoint endpoint, Message request) => new CreateUserHandler(endpoint, request.requestId);
    CreateUserHandler(CommsEndpoint endpoint, int requestId) : super(endpoint, requestId);
    
    void accept(CreateUserRequest request) {
        String sql =    "INSERT INTO user(userid, password)"
                        "VALUES('${request.userId}', '${request.password}')";
             
        db.query(sql)
            .then((_) => sendSuccess(request, "user ${request.userId} created"))
            .catchError((e) {
                String msg = "create user failed: $e";
                log.warning(msg);
                sendFail(request, msg);
            });
    }
}
