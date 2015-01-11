library db_connection;

import 'package:sqljocky/sqljocky.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;

final Logger log = new Logger('playground_server');

final ConnectionPool db = new ConnectionPool(
        host: 'localhost', 
        port: 3306, 
        user: 'webserver', 
        password: 'ruejoldy', 
        db: 'team_status', 
        max: 5);

void connectDB() {
    db.ping()
        .then((_) => print("db connection established"))
        .catchError((e) => print("db connection failed: $e"));
}
