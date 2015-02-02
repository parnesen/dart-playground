library post_collection;

import 'dart:async';
import '../../collections/server_collection_service.dart';
import '../../collections/collection_messages.dart';
import '../../../../lib/db_connection.dart';
import 'package:sqljocky/sqljocky.dart';
import 'dart:math';
import '../../util.dart';
import 'post_messages.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;

final Logger log = new Logger('postCollectionName');

//TODO: move all the client-server IO into the CollectionResponder including broadcasting, 
//and make the crud methods know nothing of the Responder and just focus on the DB work. 
class PostCollection extends Collection<String, Post> {
    
    static void init() {
        CollectionService.collectionFactories[postCollectionName] = () => new PostCollection();
    }
    
    PostCollection() : super(postCollectionName);
    
    Completer _initializedCompleter = new Completer();
    InitStatus initStatus = InitStatus.uninitialized;
    
    List<Post> posts;
    
    void open(CollectionResponder responder, OpenCollection request, String collectionName, Filter filter, int fetchUpTo) {
        if(initStatus.isUninitialized) {
            initStatus = InitStatus.initializing;
            fetchPosts()
                .then((List<Post> posts) {
                    this.posts = posts;
                    initStatus = InitStatus.initialized;
                    _initializedCompleter.complete();
                })
                .catchError((error) => _initializedCompleter.completeError(error));
        }
        
        _initializedCompleter.future
            .then((_) {
                responder.sendResult(request, new OpenCollectionSuccess(postCollectionName, posts.length));
                if(fetchUpTo > 0) {
                    responder.send(new ReadResult(0, posts.sublist(0, min(fetchUpTo, posts.length))));
                }
            })
            .catchError((error) {
                String errorMsg = "unexpected failure opening $postCollectionName: $error";
                log.warning(errorMsg, error is Error ? error.stackTrace : null);
                responder.sendFail(request, errorMsg: errorMsg);
            });
    }
    
    Future<List<Post>> fetchPosts() {
        String sql = "SELECT text, postid, user_userid, timestamp, isImportant, isTask, isStrikethrough FROM posts";
        List posts = [];
        return db.query(sql)
            .then((Results results) {
                return results.forEach((Row row) {
                    Post post = new Post(row[0], postId: row[1], userId: row[2], timestamp: row[3], isImportant: row[4] == 1, isTask: row[5] == 1, isStrikethrough: row[6] == 1);
                    posts.add(post);
                });
            })
            .then((_) {
                return posts;
            });
    }
    
    void readValues(CollectionResponder responder, ReadValues request, int startIndex, int count) {
        responder.sendResult(request, new ReadResult(startIndex, 
                startIndex < posts.length 
                    ? posts.sublist(startIndex, min(startIndex + count, posts.length))
                    : []));
    }
    
    void createValue(CollectionResponder responder, CreateValue request, Post post) {
        
        if(isSet(post.userId) && post.userId != responder.userId) {
            responder.sendFail(request, errorMsg: "Can only create post with own userId!");
        }
        
        int isImportant = post.isImportant ? 1:0;
        int isTask = post.isTask ? 1:0;
        int isStrikethrough = post.isStrikethrough ? 1:0;
        
        String insertSql = 
            "INSERT INTO posts(user_userid, text, isImportant, isTask, isStrikethrough) "
            "VALUES ('${responder.userId}', '${post.text}', '${isImportant}', '${isTask}', '${isStrikethrough}'); ";
            
        String selectSql = "SELECT postid, timestamp FROM posts WHERE postid = LAST_INSERT_ID();";
        
        db.startTransaction()
            .then((Transaction transaction) => transaction.query(insertSql)
                .then((_) => transaction.query(selectSql))
                .then((Results results) => results.last) //note use .last not .first or the commit fails because iterator still open
                .then((Row row) {
                    int postId = row[0];
                    DateTime timestamp = row[1];
                    return transaction.commit().then((_) {
                        post.json['userId'] = responder.userId;
                        post.json['postId'] = postId;
                        post.json['timestamp'] = timestamp.toString();
                        this.posts.add(post);
                        responder.sendResult(request, new ValueCreated(post));
                        broadcast(new ValuesCreated([post]));
                    });
                }))
            .catchError((e) {
                responder.sendFail(request, errorMsg : "failed to create post: $e");
            });
    }
    
    void createValues(CollectionResponder responder, CreateValues request, List<Post> posts) {
        throw "createValues not implemented";
    }
    
    void updateValues(CollectionResponder responder, UpdateValues request, List<Post> posts) {
        throw "updateValues not implemented";
    }
    
    void deleteValues(CollectionResponder responder, DeleteValues request, List<String> postIds) {        
        String commaSerparatedPostIds = toCommaSeperatedString(postIds);
        
        String sql = "DELETE FROM post WHERE postid in ($commaSerparatedPostIds)";
        db.query(sql)
            .then((_) {
                responder.sendSuccess(request);
                broadcast(new ValuesDeleted(postIds));
            })
            .catchError((e) {
                responder.sendFail(request, errorMsg : "delete posts failed: $e");
            });
    }
}