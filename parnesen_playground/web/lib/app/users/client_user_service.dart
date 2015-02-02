library client_user_service;

import '../../collections/client_collection_service.dart';
import 'user_messages.dart';

final UserCollectionService users = new UserCollectionService();

class UserCollectionService extends ClientCollectionService<String, User> {
    UserCollectionService() : super(userCollectionName);
}