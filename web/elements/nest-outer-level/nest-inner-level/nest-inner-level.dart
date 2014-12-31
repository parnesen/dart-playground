import 'package:polymer/polymer.dart';

@CustomTag('nest-inner-level')
class NestOuterLevel extends PolymerElement { NestOuterLevel.created() : super.created();
    
    void attached() {
        print("nest-inner-level-attached");
    }
}


