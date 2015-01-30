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


//TODO: move all the client-server IO into the CollectionResponder including broadcasting, 
//and make the crud methods know nothing of the Responder and just focus on the DB work. 
class UserCollection extends Collection<String, User> {
    
    final Sha1Hash _hash = new Sha1Hash(salt : config['salt']);
   
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
    
    void createValues(CollectionResponder responder, CreateValues request, List<User> users) {
        
        StringBuffer sql = new StringBuffer("INSERT INTO user(userid, firstname, lastname, role, email, password) VALUES ");
        users.forEach((User user) {
            if(!isSet(user.hashedPassword)) {
                responder.sendFail(request, errorMsg : "password missing for user ${user.userId}");
                return;
            }
            String comma = user == users.last ? '' : ',';
            String password = _hash[user.hashedPassword];
            sql.write("('${user.userId}', '${user.firstName}', '${user.lastName}', '${user.role}', '${user.email}', '${_hash[user.hashedPassword]}')$comma");
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
        
        sql.write(" WHERE userid IN ($userIds)");
        
        db.query(sql.toString())
            .then((_) {
                responder.sendSuccess(request);
                broadcast(new ValuesUpdated(users));
            })
            .catchError((e) => responder.sendFail(request, errorMsg : "update users failed: $e"));
    }
    
    void deleteValues(CollectionResponder responder, DeleteValues request, List<String> userIds) {
        StringBuffer commaSerparatedUserIds = 
            userIds.fold(
                new StringBuffer(), 
                (StringBuffer strBuf, String userId) {
                    String comma = userId == userIds.last ? '' : ',';
                    strBuf.write("'$userId'$comma "); 
                    return strBuf;
                }
            );
        
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
        String sql = "SELECT userid, firstname, lastname, role, email, isadmin FROM user";
        return db.query(sql).then((Results results) {
            List users = [];
            return results.forEach((Row row) {
                User user = new User(row[0], row[1], row[2], row[3], row[4], isAdmin : row[5] == 1);
                users.add(user);
            }).then((_) => users);
        });
    }    
}