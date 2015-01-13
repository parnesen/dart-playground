library posts_message_handlers.dart;

import 'package:parnesen_share/mail/mail_server.dart';
import 'package:parnesen_share/messages/posts_messages.dart';

void registerPostsRequestHandlers() {
    Client.requestHandlers.addAll({
        CreatePost.NAME : _createPost
    });
}

void _createPost(Client client, CreatePost request) {
    Post post = request.post;
    client.sendSuccess(request, "post with text ${post.text} created");
}