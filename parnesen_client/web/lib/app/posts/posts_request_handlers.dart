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
        requests.listen((Request<CreatePost> request) => recieve(request, request.message.post));
    }
    
    void recieve(Request request, Post post) {
        request.sendSuccess(comment : "post with text ${post.text} created");
    }
}