import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;

final Logger log = new Logger('PlaygroundHome');

@CustomTag('user-page')
class UserPage extends PolymerElement {
    UserPage.created() : super.created();
    void goHome() => Route.home.go();
}

