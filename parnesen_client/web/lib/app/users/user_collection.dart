library user_collection;

import 'dart:async';
import 'user_messages.dart';
import '../../collections/collection_service.dart';
import '../../collections/collection_messages.dart';
import '../../messaging/messaging.dart';
import '../../../../lib/db_connection.dart';
import 'package:sqljocky/sqljocky.dart';
import 'dart:math';


class UserCollection extends Collection<String, User> {
   
    
    static void init() {
        CollectionService.collectionFactories[userCollectionName] = () => new UserCollection();
    }
    
    UserCollection() : super(userCollectionName);
    
    void open(Request request, String collectionName, Filter filter, int fetchUpTo) {
        fetchUsers().then((List<User> users) {
            request.send(new OpenCollectionSuccess(userCollectionName, users.length, users.sublist(0, min(fetchUpTo, users.length))));
        });
    }
    
    void createValues(Request request, List<User> users) {
        
        StringBuffer sql = new StringBuffer("INSERT INTO user(userid, password) VALUES ");
        users.forEach((user) {
            String comma = user == users.last ? '' : ',';
            sql.write("('${user.userId}', '${user.password}')$comma");
        });
        
        db.query(sql.toString())
            .then((_) {
                request.sendSuccess(comment : users.length == 1 ? "user ${users.first.userId} created" : "${users.length} users created");
                broadcast(new ValuesCreated(users));
            })
            .catchError((e) => request.sendFail(errorMsg : "create user failed: $e"));
    }
    
    void readValues(Request request, int startIndex, int count) {
        fetchUsers().then((List<User> users) {
            request.send(new ReadResult(startIndex, 
                    startIndex < users.length 
                        ? users.sublist(startIndex, min(startIndex + count, users.length))
                        : []));
        });
    }
    
    void updateValues(Request request, List<User> users) {
//        UPDATE mytable
//            SET myfield = CASE other_field
//                WHEN 1 THEN 'value'
//                WHEN 2 THEN 'value'
//                WHEN 3 THEN 'value'
//            END
//        WHERE id IN (1,2,3)
        
        String userIds = 
            users.fold(
                new StringBuffer(), 
                (strBuf, user) {
                    String comma = user == users.last ? '' : ',';
                    strBuf.write("${user.userId}$comma");
                }
            ).toString();
        
        StringBuffer sql = new StringBuffer("UPDATE users      SET password = CASE userid");
        users.forEach((user) => sql.write("WHEN '${user.userId}' THEN '${user.password}'"));
        sql.write("END     WHERE userid IN ($userIds)");
        
        db.query(sql.toString())
            .then((_) {
                request.sendSuccess();
                broadcast(new ValuesUpdated(users));
            })
            .catchError((e) => request.sendFail(errorMsg : "update users failed: $e"));
    }
    
    void deleteValues(Request request, List<String> userIds) {
        StringBuffer commaSerparatedUserIds = 
            userIds.fold(
                new StringBuffer(), 
                (strBuf, userId) {
                    String comma = userId == userIds.last ? '' : ',';
                    strBuf.write("$userId$comma"); 
                }
            );
        
        String sql = "DELETE FROM user WHERE user in ($commaSerparatedUserIds)";
        db.query(sql)
            .then((_) {
                request.sendSuccess();
                broadcast(new ValuesDeleted(userIds));
            })
            .catchError((e) => request.sendFail(errorMsg : "delete users failed: $e"));
    }
    
    //TODO: this is extremely inefficient for large tables
    Future<List<User>> fetchUsers() {
        String sql = "SELECT userid, password FROM user";
        return db.query(sql).then((Results results) {
            List users = [];
            return results.forEach((Row row) {
                User user = new User(row[0], row[1]);
                users.add(user);
            }).then((_) => users);
        });
    }
    
}