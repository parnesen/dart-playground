library mail_server;

import 'dart:io';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'package:quiver/check.dart';
import 'mail_share.dart';
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
                message = jsonToMessage(JSON.decode(str));
            }
            catch(error) {
                log.warning("Unable to parse string as Message: '$str' due to error $error");
                return;
            }
            
            RequestHandler handler = requestHandlers[message.name];
            if(handler == null) {
                String errorMessage = "No MessageHandler registered for message of type ${message.name}";
                log.warning(errorMessage);
                if(message.requestId != null) {
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
                if(message.requestId != null) {
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
    
    void sendSuccess(Message request, [String comment] ) => send(new GenericSuccess(request, comment : comment));
    void sendFail   (Message request, [String errorMsg]) => send(new GenericFail(request, errorMsg : errorMsg));
    
    /** Configures the given [response] message as a reply to the given [request] and sends it **/
    void sendReply(Message request, Message response, { bool isFinal : true, Result result : null, String comment : null }) {
        checkState(request.requestId != null && request.requestId > 0, message : "no requestId specified on supposed request $request");
        checkState(request.mailboxId != null && request.mailboxId > 0, message : "no mailboxId specified on supposed request $request");
        
        response.json['requestId'] = request.requestId;
        response.json['mailboxId'] = request.mailboxId;
        response.json['isFinal'] = isFinal;
        
        if(result  != null) { response.json['result'] = result;   }
        if(comment != null) { response.json['comment'] = comment; }
        
        send(response);
    }
}

