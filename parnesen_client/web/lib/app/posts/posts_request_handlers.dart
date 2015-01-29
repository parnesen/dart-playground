library posts_message_handlers.dart;

import '../../messaging/messaging.dart';
import 'posts_messages.dart';

void registerPostsRequestHandlers() {
    CommsEndpoint.responderFactories.addAll({
        CreatePost.NAME : (CommsEndpoint endpoint, Message request) => new CreatePostHandler(endpoint, request.exchangeId)
    });
}

class CreatePostHandler extends Responder {

    CreatePostHandler(CommsEndpoint endpoint, int exchangeId) : super(endpoint, exchangeId) {
        requests.listen((CreatePost request) => recieve(request, request.post));
    }
    
    void recieve(Request request, Post post) {
        sendSuccess(request, comment : "post with text ${post.text} created");
    }
}