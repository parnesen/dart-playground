import 'package:polymer/polymer.dart';
import 'dart:html';
import '../playground-route/playground-route.dart';

@CustomTag('playground-counter')
class PlaygroundCounter extends PolymerElement {
    PlaygroundCounter.created() : super.created();
      
    @observable int clickCount = 0;
    ButtonElement _incrementBtn, _decrementBtn;
    
    void attached() {
        _incrementBtn = $['incrementBtn'];
        _decrementBtn = $['decrementBtn'];
        
        _decrementBtn.onClick.listen((_) => decrement());
    }
  
    //wired up from the html template
    void increment() {
        clickCount++;
        _incrementBtn.text = "Increment Again!";
    }
    
    //wired up from the attached() method using an event subscription
    void decrement() {
        clickCount--;
        _decrementBtn.text = "Decrement Again!";
    }
    
    void goHome() => Route.home.go();
}


