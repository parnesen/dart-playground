library playgroundNest;

import 'package:polymer/polymer.dart';
import '../playground-route/playground-route.dart';
import 'nest-inner-level/nest-inner-level.dart';
import 'dart:html';

@CustomTag('nest-outer-level')
class NestOuterLevel extends PolymerElement { NestOuterLevel.created() : super.created();
    
    DivElement _listDiv;
    
    void attached() {
        _listDiv = $['inner-level-list'];
        
        for(int ii = 1; ii <= 100; ii++) {
            //this demonstrates how to initialize customer Polymer elements with custom Dart Objects
            NestInnerLevel innerElement = new NestInnerLevel(new Argument(ii));
            _listDiv.children.add(innerElement);
        }
    }
    
    void goHome() => Route.home.go();
    

}




