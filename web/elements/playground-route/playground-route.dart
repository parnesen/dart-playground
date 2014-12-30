library playgroundRoute;

import 'package:polymer/polymer.dart';
import 'package:route_hierarchical/client.dart';
import 'dart:html';

typedef Element RoutePathElementCreator();

PlaygroundRoute _routeElement;
Router _router = new Router();

class Route {
    static final Route home      = new Route._create("home",    "/",         () => new Element.tag('playground-home'), isDefault : true);
    static final Route counter   = new Route._create("counter", "/counter",  () => new Element.tag('playground-counter'));
    
    static final List<Route> all = [home, counter];
    
    String name, path;
    bool isDefault;
    RoutePathElementCreator createElement;
    
    Route._create(this.name, this.path, this.createElement, {this.isDefault : false});
    
    void _register() {
        _router.root.addRoute(
            name: name, 
            defaultRoute: isDefault, 
            path: path, 
            enter: _enter
        );
    }
    
    void _enter(RouteEvent) {
        print("Routing to: $name");
        Element element = createElement();
        _routeElement.routerDiv.children  ..clear()
                                          ..add(element);
    }
    
    void go({Map parameters}) {
        _router.go(name, parameters != null ? parameters : {});
    }
}


@CustomTag('playground-route')
class PlaygroundRoute extends PolymerElement {
    
    PlaygroundRoute.created() : super.created() {
        _routeElement = this;
    }
    
    DivElement routerDiv;
    
    void attached() {
        routerDiv = $['routerDiv'];
        routerDiv.setInnerHtml("playground-route");
        
        Route.all.forEach((Route route) => route._register());
        
        _router.listen();
    }
}


