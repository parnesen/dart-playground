library user_table;

import 'package:polymer/polymer.dart';
import 'dart:html';
import '../../lib/app/users/user_messages.dart';
import '../../index.dart';
import '../../lib/messaging/messaging.dart';
import '../../lib/collections/collection_messages.dart';


@CustomTag('user-table')
class UserTable extends PolymerElement { UserTable.created() : super.created();
    
    @observable int userCount = 0;
    @observable String output = "";
    
    TableElement tableElement;
    List<Element> get rows => tableElement.tBodies.single.children;
    
    Exchange userExchange;
    
    bool isAttached = false;
    
    void attached() {
        isAttached = true;
        tableElement  = $['table'];
        userExchange  = comms.newExchange();      
        comms.whenLoggedIn.then((_) => openCollection());
        
        userExchange.stream.listen((Message message) {
            if      (message is ReadResult)    { onReadResult(message.startIndex, message.values); }
            else if (message is ValuesCreated) { usersCreated(message.values); }
            else if (message is ValuesUpdated) { usersUpdated(message.values); }
            else if (message is ValuesDeleted) { usersDeleted(new Set.from(message.values)); }
        });
        
        webSocketController.open();
    }
    
    void openCollection() {
        if(!isAttached || !comms.isLoggedIn) { return; }
        userExchange.sendRequest(new OpenCollection(userCollectionName, new Filter(), fetchUpTo: 1000))
            .then((Result result) { 
                if (result.isFail) { throw "Failed to open UserCollection: $result"; }
                else if(result is OpenCollectionSuccess) { 
                    userCount = result.collectionSize; 
                    comms.whenLoggedOut.then((_) { 
                        if(isAttached) {
                            rows.clear();
                            comms.whenLoggedIn.then((_) => openCollection()); 
                        }
                    });
                }
            })
            .catchError((error) => output = "!!$error!!");
    }
    
    void detached() {
        isAttached = false;
        userExchange.dispose();
    }
    
    void onReadResult(int startIndex, List<User> users) {
        users.forEach((User user) => setRowCells(tc.addRow(), user));
    }
    
    void usersCreated(List<User> users) {
        userCount += users.length;
        users.forEach((User user) {
            int insertIndex = getInsertIndexOf(user.userId);
            setRowCells(tc.insertRow(insertIndex), user);
        });
    }
    
    void usersUpdated(List<User> users) {
        users.forEach((User user) {
            TableRowElement row = rows.firstWhere((TableRowElement row) => row.children.first.innerHtml == user.userId);
            if(row != null) {
                setRowCells(row, user);
            }
        });
    }
    
    void usersDeleted(Set<String> userIds) {
        userCount -= userIds.length;
        userIds.forEach((String userId) {
            int rowIndex = getRowIndexOf(userId);
            if(rowIndex != null) {
                rows.removeAt(rowIndex);
            }
        });
    }
    
    void setRowCells(TableRowElement row, User user) {
      row
        ..children.clear()
        ..addCell().text = user.userId
        ..addCell().text = user.firstName
        ..addCell().text = user.lastName
        ..addCell().text = user.role
        ..addCell().text = user.email
        ..addCell().children.add(new ButtonElement()
                                        ..innerHtml = "Delete"
                                        ..onClick.listen((_) => delete(user.userId)));
    }    
    
    void delete(String userId) {
        userExchange.sendRequest(new DeleteValues([userId]))
            .then((Result result) { 
                if(result.isFail) {
                    output = result is UserNotAdmin ? "Permission Denied" : "Unexpected Error: $result";
                }
            });
    }
    
    //TODO: binary search
    int getRowIndexOf(String userId) {
        List<Element> tableRows = rows;
        for (int ii = 1; ii < rows.length; ii++) {
            TableRowElement tr = rows[ii];
            String rowUserId = tr.children[0].innerHtml;
            if(rowUserId == userId) {
                return ii;
            }
        }
        return null;
    }

    //TODO: binary search
    int getInsertIndexOf(String userId) {
        List<Element> tableRows = rows;
        for (int ii = 1; ii < rows.length; ii++) {
            TableRowElement tr = rows[ii];
            String rowUserId = tr.children[0].innerHtml;
            if(rowUserId.compareTo(userId) > 0) {
                return ii;
            }
        }
        return tc.children.length;
    }
    

}




