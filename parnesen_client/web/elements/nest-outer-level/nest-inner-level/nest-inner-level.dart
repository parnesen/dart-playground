import 'package:polymer/polymer.dart';
import 'dart:html';

@CustomTag('nest-inner-level')
class NestInnerLevel extends PolymerElement {
    
    @observable Argument myValue;

    factory NestInnerLevel(Argument val) {
        //this seems to be a bit of magic. You can't create a regular constructor
        //because Element doesn't have a default constructor. Only the browser Document can 
        //create an element, but it'll create one of the right kind, so you get back 
        //an instance of yourself here. Then you can set your member variables. 
        //WARNING: the html will BIND to the dart element BEFORE you get a chance to set your 
        //member variables, so if you want them to have an impact, they must be @observable
        NestInnerLevel element = new Element.tag('nest-inner-level');
        element.myValue = val;
        return element;
    }
    
    NestInnerLevel.created() : super.created();
}

class Argument {
    int value;
    Argument(this.value);
}


