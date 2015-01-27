library user_collection;

import 'dart:async';
import 'user_messages.dart';
import '../../collections/server_collection_service.dart';
import '../../collections/collection_messages.dart';
import '../../messaging/messaging.dart';
import '../../../../lib/db_connection.dart';
import 'package:sqljocky/sqljocky.dart';
import 'dart:math';
import '../../util.dart';
import '../../sha1_hash.dart';

class UserCollection extends Collection<String, User> {
    
    final Sha1Hash _hash = new Sha1Hash(salt : config['salt']);
   
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
        
        StringBuffer sql = new StringBuffer("INSERT INTO user(userid, firstname, lastname, role, email, password) VALUES ");
        users.forEach((User user) {
            if(!isSet(user.hashedPassword)) {
                request.sendFail(errorMsg : "password missing for user ${user.userId}");
                return;
            }
            String comma = user == users.last ? '' : ',';
            String password = _hash[user.hashedPassword];
            sql.write("('${user.userId}', '${user.firstName}', '${user.lastName}', '${user.role}', '${user.email}', '${_hash[user.hashedPassword]}')$comma");
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
        
        sql.write(" SET password = CASE userid");
        users.forEach((User user) => sql.write("WHEN '${user.userId}' THEN '${_hash[user.hashedPassword]}'"));
        sql.write("END");
        
        sql.write(" WHERE userid IN ($userIds)");
        
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
        String sql = "SELECT userid, firstname, lastname, role, email FROM user";
        return db.query(sql).then((Results results) {
            List users = [];
            return results.forEach((Row row) {
                User user = new User(row[0], row[1], row[2], row[3], row[4]);
                users.add(user);
            }).then((_) => users);
        });
    }    
}