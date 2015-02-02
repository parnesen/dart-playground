library initializable;

import 'dart:async';
import 'package:quiver/check.dart';

class Initializable<T extends Initializable> {
    
    bool get initialized => _initialized;
    void set initialized(bool val) => setInitialized(val);
    
    Future get whenInitialized   => _whenInitialized.future;
    Future get whenUninitialized => _whenUninitialized.future;
    Stream<T> get initUpdates => _initStream.stream;
    Stream<Initializable> get dependencyUpdates => _dependencyStream.stream;
    
    bool isAllDependenciesInitialized() => _dependencies.fold(true, (bool currVal, Initializable dependency) => currVal && dependency.initialized);

    Stream<Initializable> addDependencies(List<Initializable> dependencies) {
        Set<Initializable> newDependencies = new Set.from(dependencies).difference(_dependencies);
        _dependencies.addAll(newDependencies);
        
        newDependencies.forEach((Initializable dependency) {
            dependency.initUpdates.listen((Initializable dependency) => _dependencyStream.add(dependency));
        });
        return dependencyUpdates;
    }
    
    final Set<Initializable> _dependencies = new Set();
    bool _initialized = false;
    Completer _whenInitialized = new Completer();
    Completer _whenUninitialized = new Completer()..complete();
    final StreamController<T> _initStream = new StreamController.broadcast();
    final StreamController<Initializable> _dependencyStream = new StreamController.broadcast();
    
    void setInitialized(bool val) {
        if(checkNotNull(val) == _initialized) { return; }
        
        _initialized = val;
        _initStream.add(this);
        if(_initialized) {
            _whenInitialized.complete();
            _whenUninitialized = new Completer();
        }
        else {
            _whenUninitialized.complete();
            _whenInitialized = new Completer();
        }
    }
}