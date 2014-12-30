//// Copyright (c) 2014, <your name>. All rights reserved. Use of this source code
//// is governed by a BSD-style license that can be found in the LICENSE file.
//
//import 'dart:html';
//import 'package:route_hierarchical/client.dart';
//import 'package:polymer/polymer.dart';
//
//Router router = new Router();
//DivElement routerDiv;
//
//main() {
//    initPolymer().run(() {
//        // Code here is in the polymer Zone, which ensures that
//        // @observable properties work correctly.
//        Polymer.onReady.then((_) {
//            initRouter();
//        });
//    });
//    Element element = new Element.tag
//}
//
//void initRouter() {
//    routerDiv = querySelector('#routerDiv');
//    
//    router.root
//        ..addRoute(
//            name: 'home', 
//            defaultRoute: true, 
//            path: '/', 
//            enter: routeHome)
//        ..addRoute(
//            name: 'counter', 
//            path: '/counter', 
//            enter: routeCounter);
//
//    router.listen();
//}
//
//void routeHome(RouteEvent e) {
//    
//    final NodeValidatorBuilder htmlValidator = new NodeValidatorBuilder.common()
//      ..allowElement('button', attributes: ['on-click']);
//    
////    routerDiv.setInnerHtml(
////        """
////            <div>
////                <h1>Home Page</h1>
////                <button on-click="{{counterRequested}}">Counter</button>
////            </div> 
////        """, validator: htmlValidator);
//    
//    routerDiv.setInnerHtml(
//        """
//            <playground-counter></playground-counter>
//        """);
//}
//
//void counterRequested() { 
//    router.go('counter', {}); 
//}
//
//void routeCounter(RouteEvent e) {
//    //String param = e.parameters['initialValue'];
//    try {
//        //int initialValue = int.parse(param);
//        Element contents = new Element.html("""
//            <playground-counter></playground-counter>
//        """);
//        routerDiv.children.clear();
//        routerDiv.children.add(contents);
//    }
//    on Exception {
//        router.go('home', {});
//    }
//}
