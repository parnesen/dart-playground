library services;

import 'package:quiver/check.dart';

typedef T ServiceFactory<T>();

//the global instance
Services services = new Services();

void main() {}

class Services {
    

    
    final Map<Type, _Struct> instances = {};
    
    //to be called by the static instance() methods of concrete services
    Object get(Type type, ServiceFactory defaultFactory) {
        checkNotNull(type);
        checkNotNull(defaultFactory);
        
        _Struct struct = instances[type];
        if(struct == null) {
            return _create(type, defaultFactory);
        }
        
        switch(struct.state) {
            case State.instantiated : return struct.instance;
            case State.uninstantiated : return _create(type, defaultFactory);
            case State.instantiating : throw new CircularDependancyException(type);
        }

        throw new Exception("illegal state");
    }
    
    /**
     * sets the factory to use to instantiate the given type
     * must be done before the first attempt to get the service
     */
    void setFactory(Type type, ServiceFactory factory) {
        _Struct struct = instances[type];
        if(struct != null) {
            checkState(struct.state == State.uninstantiated);
        }
        else {
            struct = new _Struct()
                ..state = State.uninstantiated
                ..type = type;
            instances[type] = struct;
        }
        struct.factory = factory;
    }
    
    Object _create(Type type, ServiceFactory defaultFactory) {
        _Struct struct = new _Struct()
            ..state = State.instantiating
            ..type = type;

        instances[type] = struct;
        
        Object instance = struct.factory != null ? struct.factory() : checkNotNull(defaultFactory());
                
        struct
            ..instance = instance
            ..state = State.instantiated;
        
        return instance;
    }
}

//poor man's enum
class State { 
    static const State uninstantiated = const State._create("uninstantiated");
    static const State instantiating  = const State._create("instantiating");
    static const State instantiated   = const State._create("instantiated");
    
    final String name;
    const State._create(this.name);
}

class _Struct {
    State state = State.uninstantiated;
    Type type;
    Object instance;
    ServiceFactory factory;
}

class CircularDependancyException implements Exception {
    Type type;
    CircularDependancyException(this.type);
    String toString() => "CircularDependancyException $type";
}