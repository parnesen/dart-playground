library user_request_handlers.dart;

import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'package:parnesen_share/mail/mail_server.dart';
import 'package:parnesen_share/messages/user_messages.dart';
import 'db_connection.dart';

final Logger log = new Logger('user_request_handlers');

void registerUserRequestHandlers() {
    Client.requestHandlers.addAll({
        CreateUserRequest.NAME: _createUser,
    });
}

void _createUser(final Client client, final CreateUserRequest request) {
    
    String sql =    "INSERT INTO user(userid, password)"
                    "VALUES('${request.userId}', '${request.password}')";
         
    db.query(sql)
        .then((_) => client.sendSuccess(request, "user ${request.userId} created"))
        .catchError((e) {
            String msg = "create user failed: $e";
            log.warning(msg);
            client.sendFail(request, msg);
        });
}
