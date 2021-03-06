library user_collection;

import 'dart:async';
import 'user_messages.dart';
import '../../collections/server_collection_service.dart';
import '../../collections/collection_messages.dart';
import '../../db_connection.dart';
import 'package:sqljocky/sqljocky.dart';
import 'dart:math';
import '../../util.dart';
import '../../sha1_hash.dart';
import '../../messaging/messaging.dart';


//TODO: move all the client-server IO into the CollectionResponder including broadcasting, 
//and make the crud methods know nothing of the Responder and just focus on the DB work. 
class UserCollection extends Collection<String, User> {
    
    final Sha1Hash _saltedHash = new Sha1Hash(salt : config['salt']);
   
    static void init() {
        CollectionService.collectionFactories[userCollectionName] = () => new UserCollection();
    }
    
    UserCollection() : super(userCollectionName);
    
    void open(CollectionResponder responder, OpenCollection request, String collectionName, Filter filter, int fetchUpTo) {
        fetchUsers().then((List<User> users) {
            responder.sendResult(request, new OpenCollectionSuccess(userCollectionName, users.length));
            if(fetchUpTo > 0) {
                responder.send(new ReadResult(0, users.sublist(0, min(fetchUpTo, users.length))));
            }
        });
    }
    
    void createValue(CollectionResponder responder, CreateValue request, User user) {
        createValues(responder, request, [user]);
    }
    
    void createValues(CollectionResponder responder, Request request, List<User> users) {
        
        StringBuffer sql = new StringBuffer("INSERT INTO user(userid, firstname, lastname, role, email, password) VALUES ");
        users.forEach((User user) {
            if(!isSet(user.hashedPassword)) {
                responder.sendFail(request, errorMsg : "password missing for user ${user.userId}");
                return;
            }
            String comma = user == users.last ? '' : ',';
            String password = _saltedHash[user.hashedPassword];
            sql.write("('${user.userId}', '${user.firstName}', '${user.lastName}', '${user.role}', '${user.email}', '${_saltedHash[user.hashedPassword]}')$comma");
        });
        
        db.query(sql.toString())
            .then((_) {
                responder.sendSuccess(request, comment : users.length == 1 ? "user ${users.first.userId} created" : "${users.length} users created");
                broadcast(new ValuesCreated(users));
            })
            .catchError((e) => responder.sendFail(request, errorMsg : "create user failed: $e"));
    }
    
    void readValues(CollectionResponder responder, ReadValues request, int startIndex, int count) {
        fetchUsers().then((List<User> users) {
            responder.sendResult(request, new ReadResult(startIndex, 
                    startIndex < users.length 
                        ? users.sublist(startIndex, min(startIndex + count, users.length))
                        : []));
        });
    }
    
    void updateValues(CollectionResponder responder, UpdateValues request, List<User> users) {
//        UPDATE mytable
//            SET myfield = CASE other_field
//                WHEN 1 THEN 'value'
//                WHEN 2 THEN 'value'
//                WHEN 3 THEN 'value'
//            END
//        WHERE id IN (1,2,3)
        
        String userIds = toCommaSeperatedString(users, stringify: (User user) => user.userId);
        StringBuffer sql = new StringBuffer("UPDATE users");
                
        sql.write(" SET firstname = CASE userid");
        users.forEach((User user) => sql.write("WHEN '${user.userId}' THEN '${user.firstName}'"));
        sql.write("END");
        
        sql.write(" SET lastname = CASE userid");
        users.forEach((User user) => sql.write("WHEN '${user.userId}' THEN '${user.lastName}'"));
        sql.write("END");
        
        sql.write(" SET role = CASE userid");
        users.forEach((user) => sql.write("WHEN '${user.userId}' THEN '${user.role}'"));
        sql.write("END");
        
        sql.write(" SET email = CASE userid");
        users.forEach((User user) => sql.write("WHEN '${user.userId}' THEN '${user.email}'"));
        sql.write("END");
        
        //we don't allow password resets via update
        
        sql.write(" WHERE userid IN ($userIds)");
        
        db.query(sql.toString())
            .then((_) {
                responder.sendSuccess(request);
                broadcast(new ValuesUpdated(users));
            })
            .catchError((e) => responder.sendFail(request, errorMsg : "update users failed: $e"));
    }
    
    void deleteValues(CollectionResponder responder, DeleteValues request, List<String> userIds) {

        if(!responder.endpoint.isAdmin) {
            responder.sendResult(request, new UserNotAdmin());
            return;
        }
        
        if(userIds.contains(responder.userId)) {
            responder.sendFail(request, errorMsg: "Cannot delete own user");
            return;
        }
        
        String commaSerparatedUserIds = toCommaSeperatedString(userIds, useQuotes: true);
        
        String sql = "DELETE FROM user WHERE userid in ($commaSerparatedUserIds)";
        db.query(sql)
            .then((_) {
                responder.sendSuccess(request);
                broadcast(new ValuesDeleted(userIds));
            })
            .catchError((e) {
                responder.sendFail(request, errorMsg : "delete users failed: $e");
            });
    }
    
    //TODO: this is extremely inefficient for large tables
    Future<List<User>> fetchUsers() {
        String sql = "SELECT userid, firstname, lastname, role, email, isAdmin FROM user";
        return db.query(sql).then((Results results) {
            List users = [];
            return results.forEach((Row row) {
                User user = new User(row[0], row[1], row[2], row[3], row[4], isAdmin : row[5] == 1);
                users.add(user);
            }).then((_) => users);
        });
    }    
}