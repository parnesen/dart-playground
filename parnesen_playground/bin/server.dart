// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library playground_server;

import 'dart:io';
import 'package:route/server.dart' show Router;
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import '../web/lib/messaging/messaging.dart';
import '../web/lib/app/posts/post_messages.dart';
import '../web/lib/app/users/user_messages.dart';
import '../web/lib/app/posts/post_collection.dart';
import '../web/lib/db_connection.dart';
import '../web/lib/app/users/login_responder.dart';
import '../web/lib/collections/server_collection_service.dart';
import '../web/lib/app/users/user_collection.dart';
import '../web/lib/collections/collection_messages.dart';
import '../web/lib/util.dart';



final Logger log = new Logger('playground_server');

int sharedState = 1;

/**
 * Handle an established [WebSocket] connection.
 *
 * The WebSocket can send search requests as JSON-formatted messages,
 * which will be responded to with a series of results and finally a done
 * message.
 */
void handleWebSocket(WebSocket webSocket) {
    log.info('New WebSocket connection');
    CommsEndpoint endpoint = new CommsEndpoint.serverSide(webSocket.add);
    webSocket.listen(endpoint.receive, onError: (error) => log.warning('Bad WebSocket request: $error'));
    webSocket.done.then((val) { 
        log.info("websocket closed: $val");
        endpoint.dispose();
    });
}

void main() {
    
    config['salt'] = "fl23Fkfj0fjdsiebw";
    
    // Set up logger.
    Logger.root.level = Level.CONFIG;
    Logger.root.onRecord
        .listen((LogRecord rec) {
            String stacktrace = rec.stackTrace != null ? "\n${rec.stackTrace}" : "";
            print('${rec.loggerName}[${rec.level.name}] ${rec.time}: ${rec.message} $stacktrace'); 
        });

    int port = 9250;
      
    registerCollectionMessages();
    registerPostMessages();
    registerUserMessages();
    registerLoginRequestHandlers();
    CollectionService.init();
    UserCollection.init();
    PostCollection.init();
      
    connectDB();
    
    HttpServer.bind(InternetAddress.ANY_IP_V4, port).then((server) {
      log.info("Websocket server is running on "
               "'http://${server.address.address}:$port/'");
      var router = new Router(server);
    
      // The client will connect using a WebSocket. Upgrade requests to '/ws' and
      // forward them to 'handleWebSocket'.
      router.serve('/ws')
        .transform(new WebSocketTransformer())
        .listen(handleWebSocket);
    
    });
  

}
