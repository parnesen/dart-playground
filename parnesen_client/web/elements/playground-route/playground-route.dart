library playgroundRoute;

import 'package:polymer/polymer.dart';
import 'package:route_hierarchical/client.dart';
import 'dart:html';
import 'package:quiver/check.dart';

typedef void RouteFunction(RouteEvent);

Router _router = new Router();
DivElement _routerDiv;

class Route {
    
    static Element _counterElement = null;
    
    static final Route home = new Route._create(
            "home", 
            "/playground/home", 
            (RouteEvent) => _showElement(new Element.tag('playground-home')), 
            isDefault : true);
    
    static final Route counter = new Route._create(
            "counter", 
            "/playground/counter", 
            (RouteEvent) => _showElement(new Element.tag('playground-counter')));
    
    static final Route nest = new Route._create(
            "nest", 
            "/playground/nest", 
            (RouteEvent) => _showElement(new Element.tag('nest-outer-level')));
    
    static final Route websocket = new Route._create(
            "websocket", 
            "/playground/websocket", 
            (RouteEvent) => _showElement(new Element.tag('playground-websocket')));    
    
    static final List<Route> all = [home, counter, nest, websocket];
    
    String name, path;
    bool isDefault;
    RouteFunction routeFunction;
    
    Route._create(String name, String path, RouteFunction routeFunction, {this.isDefault : false}) {
        this.name = checkNotNull(name);
        this.path = checkNotNull(path);
        this.routeFunction = checkNotNull(routeFunction);
    }
    
    void _register() {
        _router.root.addRoute(
            name: name, 
            defaultRoute: isDefault, 
            path: path, 
            enter: (RouteEvent) {
                print("Routing to: $name");
                routeFunction(RouteEvent);
            }
        );
    }
    
    void go({Map parameters}) {
        _router.go(name, parameters != null ? parameters : {});
    }
    
    static void _showElement(Element element) {
        _routerDiv.children ..clear()
                            ..add(element);
    }
}


@CustomTag('playground-route')
class PlaygroundRoute extends PolymerElement {
    
    PlaygroundRoute.created() : super.created();
    
    void attached() {
        _routerDiv = $['routerDiv'];
        Route.all.forEach((Route route) => route._register());
        _router.listen();
        Route.home.go();
    }
}
