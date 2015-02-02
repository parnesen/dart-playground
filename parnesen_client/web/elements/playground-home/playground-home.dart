import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';

@CustomTag('playground-home')
class PlaygroundHome extends PolymerElement {
    PlaygroundHome.created() : super.created();
    
    void goCounter()   => Route.counter     .go();
    void goNest()      => Route.nest        .go();
    void goUserPage()  => Route.users       .go();
    void goPostPage()  => Route.posts       .go();
}


