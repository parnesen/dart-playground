library db_connection;

import 'package:sqljocky/sqljocky.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;

final Logger log = new Logger('db_connection');

final ConnectionPool db = new ConnectionPool(
        host: 'localhost', 
        port: 3306, 
        user: 'webserver', 
        password: 'ruejoldy', 
        db: 'team_status', 
        max: 5);

void connectDB() {
    db.ping()
        .then((_) => log.info("db connection established"))
        .catchError((e) => log.info("db connection failed: $e"));
}
