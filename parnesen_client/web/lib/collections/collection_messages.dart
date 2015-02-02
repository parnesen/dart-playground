library collection_messages;

import '../messaging/messaging.dart';
import 'package:quiver/check.dart';

const String userCollectionName = "UserCollection";

void registerCollectionMessages() {
    JsonObject.factories.addAll({
        OpenCollection.NAME         : (json) => new OpenCollection.fromJson(json),
        
        OpenCollectionSuccess.NAME  : (json) => new OpenCollectionSuccess.fromJson(json),
        //GenericFail
        
        CreateValue.NAME            : (json) => new CreateValue.fromJson(json),
        ValueCreated.NAME           : (json) => new ValueCreated.fromJson(json),
        CreateValues.NAME           : (json) => new CreateValues.fromJson(json),
        ReadValues.NAME             : (json) => new ReadValues.fromJson(json),
        UpdateValues.NAME           : (json) => new UpdateValues.fromJson(json),
        DeleteValues.NAME           : (json) => new DeleteValues.fromJson(json),
        
        ValuesCreated.NAME          : (json) => new ValuesCreated.fromJson(json),
        ReadResult.NAME             : (json) => new ReadResult.fromJson(json),
        ValuesUpdated.NAME          : (json) => new ValuesUpdated.fromJson(json),
        ValuesDeleted.NAME          : (json) => new ValuesDeleted.fromJson(json),
        
        Filter.NAME                 : (json) => new Filter.fromJson(json),
    });
}

bool isCollectionUpdate(Message message) {
    if(message is ValuesCreated) return true;
    if(message is ValuesUpdated) return true;
    if(message is ValuesDeleted) return true;
    return false;
}

class Filter extends JsonObject {
    static const String NAME = "Filter";
    
    Filter.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    Filter() : super(NAME);
}

/** kicks off a conversation about collection **/
class OpenCollection extends Request {
    static const String NAME = "OpenCollection";
    
    final Filter filter;
    
    OpenCollection.fromJson(Map<String, dynamic> json) : 
        super.fromJson(json), 
        filter = jsonToObj(json['filter']) as Filter;
    
    OpenCollection(String collectionName, Filter filter, {int fetchUpTo : 0 }) : super(name : NAME), filter = filter {
        json['collectionName'] = checkNotNull(collectionName);
        json['filter'] = filter.json;
        json['fetchUpTo'] = fetchUpTo;
    }
    
    String get collectionName => json['collectionName'];
    int get fetchUpTo => json['fetchUpTo'];
}


class OpenCollectionSuccess extends Result {
    static const String NAME = "OpenCollectionSuccess";
    OpenCollectionSuccess.fromJson(Map<String, dynamic> json) :  super.fromJson(json);
    
    OpenCollectionSuccess(String collectionName, int collectionSize) :  super(name : NAME, isSuccess : true) {
        json['collectionName'] = checkNotNull(collectionName);
        json['collectionSize'] = checkNotNull(collectionSize);
    }
    
    int get collectionName => json['collectionName'];
    int get collectionSize => json['collectionSize'];
}

abstract class ValueListRequest<T extends JsonObject> extends Request {
    final List<T> values;
    
    ValueListRequest.fromJson(Map<String, dynamic> json) 
        :  super.fromJson(json)
        ,  values = new List.from((json['values'] as List).map((json) => jsonToObj(json) as T));
    
    ValueListRequest(String name, List<T> values) : super(name : name), values = values {
        checkNotNull(values);
        json['values'] = new List.from(values.map((T value) => value.json));
    }
}

abstract class ValueListResult<T extends JsonObject> extends Result {
    final List<T> values;
    
    ValueListResult.fromJson(Map<String, dynamic> json) 
        :  super.fromJson(json)
        ,  values = new List.from((json['values'] as List).map((json) => jsonToObj(json) as T));
    
    ValueListResult(String name, List<T> values) : super(name : name), values = values {
        checkNotNull(values);
        json['values'] = new List.from(values.map((T value) => value.json));
    }
}

abstract class ValueListOperation<T extends JsonObject> extends Message {
    final List<T> values;
    
    ValueListOperation.fromJson(Map<String, dynamic> json) 
        :  super.fromJson(json)
        ,  values = new List.from((json['values'] as List).map((json) => jsonToObj(json) as T));
    
    ValueListOperation(String name, List<T> values) : super(name : name), values = values {
        checkNotNull(values);
        json['values'] = new List.from(values.map((T value) => value.json));
    }
}

class ReadValues extends Request {
    static const String NAME = "ReadValues";
    ReadValues.fromJson(Map<String, dynamic> json) :  super.fromJson(json);
    
    ReadValues(int startIndex, int count) : super(name : NAME) {
        json['startIndex'] = checkNotNull(startIndex);
        json['count'] = checkNotNull(count);
    }
    
    int get startIndex => json['startIndex'];
    int get count => json['count'];
}

class ReadResult<T extends JsonObject> extends ValueListResult<T> {
    static const String NAME = "ReadResult";
    ReadResult.fromJson(Map<String, dynamic> json)  :  super.fromJson(json);
    
    ReadResult(int startIndex, List<T> values) : super(NAME, values) {
        json['startIndex'] = startIndex;
    }
    
    int get startIndex => json['startIndex'];
    List<T> get values => super.values;
}

class ValuesCreated<T extends JsonObject> extends ValueListOperation<T> {
    static const String NAME = "ValuesCreated";
    ValuesCreated.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    ValuesCreated(List<T> values) : super(NAME, values);
    List<T> get values => super.values;
}

class ValuesUpdated<T extends JsonObject> extends ValueListOperation<T> {
    static const String NAME = "ValuesUpdated";
    ValuesUpdated.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    ValuesUpdated(List<T> values) : super(NAME, values);
    List<T> get values => super.values;
}

class ValuesDeleted<K> extends Message {
    static const String NAME = "ValuesDeleted";
    ValuesDeleted.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    ValuesDeleted(List<K> values) : super(name : NAME) {
        json['values'] = values;
    }
    List<K> get values => json['values'];
}

class CreateValue<T extends JsonObject> extends Request {
    static const String NAME = "CreateValue";
    final T value;
    
    CreateValue.fromJson(Map<String, dynamic> json) : super.fromJson(json), value = jsonToObj(json['value']);
    CreateValue(T value) : super(name: NAME), value = value {
        json['value'] = value.json;
    }
}

class ValueCreated<T extends JsonObject> extends Result {
    static const String NAME = "ValueCreated";
    final T value;
    
    ValueCreated.fromJson(Map<String, dynamic> json) : super.fromJson(json), value = jsonToObj(json['value']);
    ValueCreated(T value) : super(name: NAME), value = value {
        json['value'] = value.json;
    }
}

class CreateValues<T extends JsonObject> extends ValueListRequest<T> {
    static const String NAME = "CreateValues";
    CreateValues.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    CreateValues(List<T> values) : super(NAME, values);
    List<T> get values => super.values;
}

class UpdateValues<T extends JsonObject> extends ValueListRequest<T> {
    static const String NAME = "UpdateValues";
    UpdateValues.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    UpdateValues(List<T> values) : super(NAME, values);
    List<T> get values => super.values;
}

/** a key must be a valid JSON value **/
class DeleteValues<K> extends Request {
    static const String NAME = "DeleteValues";
    DeleteValues.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    DeleteValues(List<K> keys) : super(name : NAME) {
        json['keys'] = keys;
    }
    List<K> get keys => json['keys'];
}