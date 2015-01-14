  library client_websocket_controller;
  
  import 'dart:async';
  import 'dart:html';
  import 'package:quiver/check.dart';
  import 'comms_endpoint.dart';
 
  
  final ClientWebsocketController webSocketController = new ClientWebsocketController._create();
  
  final State closedState   = new ClosedState   ._create();
  final State openingState  = new OpeningState  ._create();
  final State openState     = new OpenState     ._create();
  final State closingState  = new ClosingState  ._create();
  final State errorState    = new ErrorState    ._create();
    
  class ClientWebsocketController extends WebSocketProxy {
      
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
      
      ClientWebsocketController._create();
      State _state = closedState;
      WebSocket _webSocket;
      final StreamController<String> _streamController = new StreamController.broadcast();
      final StreamController<StateTransition> _stateTransitionController = new StreamController.broadcast();
    }
  
  typedef void _handleStateEntry();
  
  abstract class State {
      
      ClientWebsocketController get client => webSocketController;
      
      WebSocket get webSocket => client.webSocket;
      
      void _onEnter();
      void _send(String msg) => throw new StateError("not connected");
      
      Future<State> _open();
      Future<State> _close();
      
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
              print("ClientWebsocketController attempting $transition");
              try {
                  _onEnter();
              }
              catch(exception) {
                  print(exception);
                  _completer.completeError(exception);
                  _completer = null;
              }
          }
          return _completer.future;
      }
      
      void _endStateReached() {
          _reportNewState();
          _completer.complete(this);
          _completer = null;
      }
      
      void _reportNewState() {
          State prevState = client._state;
          client._state = this;
          StateTransition transition = new StateTransition(prevState, client._state);
          print("ClientWebsocketController: $transition");
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
        ClosedState._create();
        
        Future<State> _open()  => openingState._set();
        Future<State> _close() => new Future(() {});

        void _onEnter() {
            client._goal = this;
            client._webSocket = null;
            _endStateReached();
        }
    }
  
    class OpeningState extends State {
        OpeningState._create();
        
        Future _open()  => _completer.future;
        Future _close() => closingState._set();
      
        void _onEnter() {
            checkState(client.webSocket == null);
            client._goal = openState;
            _reportNewState();
            String url = 'ws://${Uri.base.host}:9250/ws';
            print("creating Websocket: $url");
            WebSocket webSocket = new WebSocket(url);
            webSocket.onOpen.first.then((_) {
                if(client._goal == openState) {
                    print("websocket open");
                    client._webSocket = webSocket;
                    openState._set();
                }
                else {
                    webSocket.close();
                }
            });
            
            webSocket.onError.first.then((ErrorEvent error) {
                print(error.message);
                if(client._goal == openState) {
                    errorState._set();
                }              
            });
        }
    }
    
    class OpenState extends State {
        OpenState._create();
        
        Future _open()  => new Future(() {});
        Future _close() => closingState._set();

        void _onEnter() {
            checkState(webSocket != null);
            checkState(client.state == openingState);
            _endStateReached();
            webSocket.onMessage.listen((MessageEvent event) {
                if(client.state == this) {
                    String message = event.data as String;
                    client._streamController.add(message);
                }
            });
        }
        
        void _send(String msg) => webSocket.send(msg);
    }
    
    class ClosingState extends State {
        ClosingState._create();
        
        Future _open()  => openingState._set();
        Future _close() => _completer.future;

        void _onEnter(){
            checkState(client._webSocket != null);
            checkState(client.state == openingState || client.state == openState);
            
            client._goal = closedState;
            _reportNewState();
            webSocket.onClose.first.then((_) {
                if(client._goal == closedState) {
                    client._webSocket = null;
                    closedState._set();
                }
            });
            webSocket.onError.first.then((ErrorEvent error) {
                print(error.message);
                if(client._goal == closedState) {
                    client._webSocket = null;
                    errorState._set();
                }          
            });
            client._webSocket.close();
        }
    }
    
    class ErrorState extends State {
        ErrorState._create();
        
        Future _open()  => openingState._set();
        Future _close() => new Future(() {});

        void _onEnter() {
            _endStateReached();
            if(client._webSocket != null) {
                client._webSocket.close();
                client._webSocket = null;
            }
        }
    }
