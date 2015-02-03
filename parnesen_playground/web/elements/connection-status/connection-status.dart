import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import '../../lib/messaging/client_websocket_controller.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import '../../index.dart';

final Logger log = new Logger('PlaygroundHome');

@CustomTag('connection-status')
class ConnectionStatus extends PolymerElement {

    ConnectionStatus.created() : super.created();

    @observable State connectionState = webSocketController.state;
    @observable String result;

    StreamSubscription stateSubscription;

    void attached() {
        super.attached();
        bool isEnterKey(KeyboardEvent event) => event.keyCode == KeyCode.ENTER;

        stateSubscription = webSocketController.stateTransitions.listen((_) {
            connectionState = webSocketController.state;
        });
    }

    void connect() {
        webSocketController.open().catchError((error) => result = "failed to connect: $error");
    }

    void disconnect() {
        webSocketController.close().catchError((error) => result = "error while disconnecting: $error");
    }

    void detached() {
        super.detached();
        stateSubscription.cancel();
    }
}

