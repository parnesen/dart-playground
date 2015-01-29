library playgroundNest;

import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import 'dart:html';
import '../../lib/util.dart';
import '../../lib/app/users/user_messages.dart';
import '../../index.dart';
import '../../lib/messaging/messaging.dart';
import '../../lib/collections/collection_messages.dart';
import 'dart:async';


@CustomTag('user-table')
class UserTable extends PolymerElement { UserTable.created() : super.created();
    
    @observable int userCount = 0;
    @observable String output = "";
    
    TableElement tableElement;
    
    Exchange userExchange;
    
    void attached() {
        
        tableElement = $['table'];
        userExchange = comms.newExchange();
        
        webSocketController.open().then((_) {
            userExchange.sendRequest(new OpenCollection(userCollectionName, new Filter(), fetchUpTo: 1000))
                .then((Result result) { 
                    if (result.isFail) throw "Failed to open UserCollection: $result";
                    else if(result is OpenCollectionSuccess) {
                        userCount = result.collectionSize;
                    }
                })
                .catchError((error) => output = "!!$error!!");
        });
        
        userExchange.stream.listen((Message message) {
            if      (message is ReadResult)    { onReadResult(message.startIndex, message.values); }
            else if (message is ValuesCreated) { usersCreated(message.values); }
            else if (message is ValuesUpdated) { usersUpdated(message.values); }
            else if (message is ValuesDeleted) { usersDeleted(new Set.from(message.values)); }
            else if (message is ReadResult)    { onReadResult(message.startIndex, message.values); }
        });
    }
    
    void detached() {
        if(userExchange != null) {
            userExchange.dispose();
        }
    }
    
    void onReadResult(int startIndex, List<User> users) {
        TableSectionElement tc = tableElement.tBodies.single;
        users.forEach((User user) {
            TableRowElement row = tc.addRow();
            row.addCell().text = user.userId;
            row.addCell().text = user.firstName;
            row.addCell().text = user.lastName;
            row.addCell().text = user.role;
            row.addCell().text = user.email;
        });
    }
    
    void usersCreated(List<User> users) {
        onReadResult(0, users);
    }
    
    void usersUpdated(List<User> users) {
//        users.forEach((User user) {
//            UserTableRow row = tableElement.children.firstWhere((child) => child is UserTableRow && child.user.userId == user.userId);
//            if(row != null) {
//                row.user = user; 
//            }
//        });
    }
    
    void usersDeleted(Set<String> userIds) {
//        for(int ii = tableElement.children.length - 1; ii >= 0; ii--) {
//            Element element = tableElement.children[ii];
//            if(element is UserTableRow && userIds.contains(element.user.userId)) {
//                tableElement.children.removeAt(ii);
//            }
//        }
    }
}




