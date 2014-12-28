import 'package:polymer/polymer.dart';


@CustomTag('simple-element')
class SimpleElement extends PolymerElement {
    SimpleElement.created() : super.created() {}
      
    @observable String content = "initial content";
    int _clickCount = 0;
  
    void onBtnClick() {
        _clickCount++;
        content = "clicked ${_clickCount} times";
    }
}


