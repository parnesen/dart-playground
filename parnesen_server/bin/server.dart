// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library playground_server;

import 'dart:io';

import 'package:http_server/http_server.dart' as http_server;
import 'package:route/server.dart' show Router;
import 'package:logging/logging.dart' show Logger, Level, LogRecord;


final Logger log = new Logger('playgroundServer');

/**
 * Handle an established [WebSocket] connection.
 *
 * The WebSocket can send search requests as JSON-formatted messages,
 * which will be responded to with a series of results and finally a done
 * message.
 */
void handleWebSocket(WebSocket webSocket) {
  log.info('New WebSocket connection');

  // Listen for incoming data. We expect the data to be a JSON-encoded String.
  webSocket
    .listen((String request) {
      print("Handling '$request'");
      for(int ii = 0; ii < 3; ii++) {
          webSocket.add(request.toUpperCase());
      }
    }, onError: (error) {
      log.warning('Bad WebSocket request: $error');
    });
}

void main() {
  // Set up logger.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  int port = 9250;

  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port).then((server) {
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
