import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';

@CustomTag('playground-home')
class PlaygroundHome extends PolymerElement {
    PlaygroundHome.created() : super.created();
    
    void attached() {
        print("playground-home attached");
    }
    
    void goCounter() => Route.counter.go();
}


