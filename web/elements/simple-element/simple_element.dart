import 'package:polymer/polymer.dart';
import 'dart:html';

@CustomTag('simple-element')
class SimpleElement extends PolymerElement {
    SimpleElement.created() : super.created() {}
      
    @observable String content = "initial content";
    int _clickCount = 0;
    ButtonElement button;
    
    void attached() {
        button = $['btn'];
    }
  
    void onBtnClick() {
        _clickCount++;
        content = "clicked ${_clickCount} times";
        button.text = "Click Me Again!";
    }
}


