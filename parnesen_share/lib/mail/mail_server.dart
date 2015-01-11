library mail_server;

import 'dart:io';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'package:quiver/check.dart';
import 'mail_message.dart';
import 'dart:convert';

final Logger log = new Logger('mail_server');

typedef void RequestHandler(Client client, Message message);

class Client {
    
    static final Map<String, RequestHandler> requestHandlers = {};
    
    final WebSocket webSocket;

    Client(WebSocket webSocket) : this.webSocket = checkNotNull(webSocket);
    
    void onReceive(String str) {
        try {
            Message message;
            try {
                message = new Message.fromString(str);
            }
            catch(error) {
                log.warning("Unable to parse string as Message: '$str' due to error $error");
                return;
            }
            
            RequestHandler handler = requestHandlers[message.name];
            if(handler == null) {
                String errorMessage = "No MessageHandler registered for message of type ${message.name}";
                log.warning(errorMessage);
                if(message is Request) {
                    sendFail(message, errorMessage);
                }
                return;
            }
            
            try {
                log.info("Handling Message $message");
                handler(this, message);
            }
            catch(error, stacktrace) {
                String msg = "RequestHandler for message '${message.name}' failed with error: $error";
                print(msg);
                print(stacktrace);
                if(message is Request) {
                    sendFail(message, msg);
                }
            }
        }
        catch(error, stacktrace) {
            log.warning("Error onReceive", error, stacktrace);
            print(error);
            print(stacktrace);
        }
    }
    
    void send(Message message) {
        log.info("Sending Message $message");
        String str = JSON.encode(message.json); 
        webSocket.add(str);
    }
    
    void sendSuccess(Request request, [String message])      => send(new Success.fromRequest(request, message));
    void sendFail   (Request request, [String errorMessage]) => send(new Fail.fromRequest(request, errorMessage));
}


//void _createUser(Client client, CreateUser request) {
//    client.sendSuccess(request, "user ${request.userId} created");
//}
//
//void _createPost(Client client, CreatePost request) {
//    Post post = request.post;
//    client.sendSuccess(request, "post with text ${post.text} created");
//}

