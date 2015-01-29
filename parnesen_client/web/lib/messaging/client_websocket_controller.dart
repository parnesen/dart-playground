  library client_websocket_controller;
  
  import 'dart:async';
  import 'dart:html';
  import 'package:quiver/check.dart';
  import 'package:logging/logging.dart' show Logger, Level, LogRecord;

  final Logger log = new Logger('client_websocket_controller');  
  
  //TODO: add in code to re-attempt connection upon connection loss: ie ReconnectingState
  class ClientWebsocketController {
      
      ClosedState closedState;
      OpeningState openingState;
      OpenState openState;
      ClosingState closingState;
      ErrorState errorState;
      
      //PUBLIC API
      
      Future open()  => state._open();
      
      Future close() => state._close();
      
      /** the stream of messages from the server*/
      Stream<String> get stream => _streamController.stream;
      
      void send(String msg) => state._send(msg);
      
      Stream<StateTransition> get stateTransitions => _stateTransitionController.stream;
      
      State get state => _state;
      /*@nullable*/ WebSocket get webSocket => _webSocket;
      
      //PRIVATE INTERNALS
      
      State _goal;
      Completer<State> completer = new Completer();
      
      State _state;
      WebSocket _webSocket;
      final StreamController<String> _streamController = new StreamController.broadcast();
      final StreamController<StateTransition> _stateTransitionController = new StreamController.broadcast();
      
      ClientWebsocketController() {
          closedState   = new ClosedState   ._create(this);
          openingState  = new OpeningState  ._create(this);
          openState     = new OpenState     ._create(this);
          closingState  = new ClosingState  ._create(this);
          errorState    = new ErrorState    ._create(this);
          
          _state = closedState;
      }
    }
  
  typedef void _handleStateEntry();
  
  abstract class State {
      
      final ClientWebsocketController client;
      
      State(ClientWebsocketController client) : client = client;
      
      WebSocket get webSocket => client.webSocket;
      
      void _onEnter();
      void _onExit() {}
      void _send(String msg) => throw new StateError("not connected");
      
      Future<State> _open();
      Future<State> _close();
      
      void _onWebSocketClosed(CloseEvent closeEvent) {
          client._webSocket = null;
          client.closedState._set();
      }
      
      void _onWebSocketError(Event errorEvent) {
          String error = "Websocket Error: $errorEvent";
          log.warning(error);
          client.errorState
                .._errorMsg = error
                .._set();          
      }
      
      Completer get _completer {
          if (client.completer == null) {
              client.completer = new Completer<State>();
          }
          return client.completer;
      }
      
      set _completer(Completer completer) => client.completer = completer;
      
      //TODO: rewrite using async/await syntax    https://www.dartlang.org/articles/await-async/
      Future<State> _set() {
          if(client.state != this) {
              StateTransition transition = new StateTransition(client.state, this);
              try {
                  client.state._onExit();
                  this._onEnter();
              }
              catch(exception, stacktrace) {
                  String error = "Error switching state[$transition]";
                  log.warning(error, exception, stacktrace);
                  _completer.completeError(exception);
                  _completer = null;
                  if(!(this is ErrorState)) {
                      client.errorState
                            .._errorMsg = error
                            .._set();      
                  }
              }
          }
          return _completer.future;
      }
      
      void _endStateReached() {
          client.errorState._errorMsg = null;
          _reportNewState();
          _completer.complete(this);
          _completer = null;
      }
      
      void _reportNewState() {
          State prevState = client._state;
          client._state = this;
          StateTransition transition = new StateTransition(prevState, client._state);
          log.info("$transition");
          client._stateTransitionController.add(transition);
      }
         
      String toString() => this.runtimeType.toString();
    }
  
    class StateTransition {
        final State oldState, newState;
        StateTransition(this.oldState, this.newState);
        String toString() => "$oldState->$newState";
    }
  
    class ClosedState extends State {
        ClosedState._create(ClientWebsocketController client) : super(client);
        
        Future<State> _open()  => client.openingState._set();
        Future<State> _close() => new Future(() {});

        void _onEnter() {
            client._goal = this;
            client._webSocket = null;
            _endStateReached();
        }
    }
  
    class OpeningState extends State {
        OpeningState._create(ClientWebsocketController client) : super(client);
        
        Future _open()  => _completer.future;
        Future _close() => client.closingState._set();
      
        void _onEnter() {
            checkState(client.webSocket == null);
            client._goal = client.openState;
            _reportNewState();
            String url = 'ws://${Uri.base.host}:9250/ws';
            log.info("creating Websocket: $url");
            
            WebSocket webSocket = new WebSocket(url);
            
            webSocket.onOpen.first.then((_) {
                if(client._goal == client.openState) {
                    log.info("websocket open");
                    client._webSocket = webSocket;
                    webSocket.onClose.listen((CloseEvent closeEvent) => client.state._onWebSocketClosed(closeEvent));
                    webSocket.onError.listen((Event errorEvent)      => client.state._onWebSocketError (errorEvent));
                    client.openState._set();
                }
                else {
                    webSocket.close();
                }
            });
            
            webSocket.onError.first.then((Event errorEvent) {
                String error = "failed to open websocket";
                log.warning(error, errorEvent);
                if(client._goal == client.openState) {
                    client.errorState
                        .._errorMsg = error
                        .._set();
                }           
            });
        }
    }
    
    class OpenState extends State {
        OpenState._create(ClientWebsocketController client) : super(client);
        
        Future _open()  => new Future(() {});
        Future _close() => client.closingState._set();
        
        StreamSubscription msgStreamSubscription;

        void _onEnter() {
            checkState(webSocket != null);
            checkState(client.state == client.openingState);
            _endStateReached();
            
            msgStreamSubscription = webSocket.onMessage.listen((MessageEvent event) {
                if(client.state == this) {
                    String message = event.data as String;
                    client._streamController.add(message);
                }
            });
        }
        
        void _onExit() {
            msgStreamSubscription.cancel();
        }
        
        void _send(String msg) => webSocket.send(msg);
    }
    
    class ClosingState extends State {
        ClosingState._create(ClientWebsocketController client) : super(client);
        
        Future _open()  => client.openingState._set();
        Future _close() => _completer.future;

        void _onEnter(){
            checkState(client._webSocket != null);
            checkState(client.state == client.openingState || client.state == client.openState);
            
            client._goal = client.closedState;
            _reportNewState();
            client._webSocket.close();
        }
    }
    
    class ErrorState extends State {
        ErrorState._create(ClientWebsocketController client) : super(client);
        
        String _errorMsg;
        
        String get errormsg => _errorMsg;
        
        Future _open()  => client.openingState._set();
        Future _close() => new Future(() {});

        void _onEnter() {
            _endStateReached();
            if(client._webSocket != null) {
                client._webSocket.close();
                client._webSocket = null;
            }
        }
        
        void _endStateReached() {
            _reportNewState();
            _completer.completeError(_errorMsg);
            _completer = null;
        }
    }
