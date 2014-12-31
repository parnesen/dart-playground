import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';

@CustomTag('nest-outer-level')
class NestOuterLevel extends PolymerElement { NestOuterLevel.created() : super.created();
    
    void attached() {
        print("nest-outer-level-attached");
    }
    
    void goHome() => Route.home.go();
}


