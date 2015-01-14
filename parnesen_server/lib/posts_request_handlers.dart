library posts_message_handlers.dart;

import 'package:parnesen_share/mail/comms_endpoint.dart';
import 'package:parnesen_share/mail/mail_share.dart';
import 'package:parnesen_share/messages/posts_messages.dart';

void registerPostsRequestHandlers() {
    CommsEndpoint.requestHandlerFactories.addAll({
        CreatePost.NAME : (CommsEndpoint endpoint, Message request) => new CreatePostHandler(endpoint, request.requestId)
    });
}

class CreatePostHandler extends RequestHandler {

    CreatePostHandler(CommsEndpoint endpoint, int requestId) : super(endpoint, requestId);
    
    void recieve(CreatePost request) {
        Post post = request.post;
        sendSuccess("post with text ${post.text} created");
    }
}