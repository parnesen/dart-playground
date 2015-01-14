library collection_handler_messages;

import 'package:parnesen_share/mail/mail_share.dart';
import 'package:quiver/check.dart';

void registerJsonObjectFactories() {
    JsonObject.factories.addAll({
        GetCollection.NAME          : (json) => new GetCollection.fromJson(json),
        GetCollectionSuccess.NAME   : (json) => new GetCollectionSuccess.fromJson(json),
        //GenericFail
        GetBatch.NAME               : (json) => new GetBatch.fromJson(json),
        BatchDownload.NAME          : (json) => new BatchDownload.fromJson(json),
        ValuesRemoved.NAME          : (json) => new ValuesRemoved.fromJson(json),
        ValuesModified.NAME         : (json) => new ValuesModified.fromJson(json),
        ValuesAdded.NAME            : (json) => new ValuesAdded.fromJson(json)
    });
}

/** kicks off a conversation about collection **/
class GetCollection extends Message {
    static const String NAME = "GetCollection";
    
    final Filter filter;
    
    GetCollection.fromJson(Map<String, dynamic> json) : 
        super.fromJson(json), 
        filter = jsonToObj(json['filter']) as Filter;
    
    GetCollection(Filter filter, { int batch_size : 50 }) : super(name : NAME), filter = filter {
        json['filter'] = filter.json;
    }
}

abstract class Filter extends JsonObject {
    Filter.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}

class GetCollectionSuccess extends Message {
    static const String NAME = "GetCollectionSuccess";
    GetCollectionSuccess.fromJson(Map<String, dynamic> json) :  super.fromJson(json);
    
    GetCollectionSuccess(int count) : super(name : NAME) {
        json['count'] = checkNotNull(count);
    }
    
    int get count => json['count'];
}

class GetBatch extends Message {
    static const String NAME = "GetBatch";
    GetBatch.fromJson(Map<String, dynamic> json) :  super.fromJson(json);
    
    GetBatch(int startIndex) : super(name : NAME) {
        json['startIndex'] = checkNotNull(startIndex);
    }
    
    int get startIndex => json['startIndex'];
}

class BatchDownload<T extends JsonObject> extends Message {
    static const String NAME = "BatchDownload";
    
    final List<T> values;
    int get startIndex => json['startIndex'];
    
    BatchDownload.fromJson(Map<String, dynamic> json) 
        :  super.fromJson(json)
        ,  values = new List.from((json['values'] as List).map((json) => jsonToObj(json) as T));
    
    BatchDownload(int startIndex, List<T> values) : super(name : NAME), values = values {
        json['startIndex'] = startIndex;
        json['values'] = new List.from(values.map((T value) => value.json));
    }
}

class ValuesAdded<T extends JsonObject> extends Message {
    static const String NAME = "ValuesAdded";
    
    final List<T> values;
    
    ValuesAdded.fromJson(Map<String, dynamic> json) 
        :  super.fromJson(json)
        ,  values = new List.from((json['values'] as List).map((json) => jsonToObj(json) as T));
    
    ValuesAdded(List<T> values) : super(name : NAME), values = values {
        json['values'] = new List.from(values.map((T value) => value.json));
    }
}

class ValuesRemoved extends Message {
    static const String NAME = "ValuesRemoved";
    
    List get ids => json['ids'] as List;
    
    ValuesRemoved.fromJson(Map<String, dynamic> json) : super.fromJson(json);
    
    ValuesRemoved(List ids) : super(name : NAME) {
        json['ids'] = ids;
    }
}

class ValuesModified<T extends JsonObject> extends Message {
    static const String NAME = "ValuesModified";
    
    final List<T> values;
    
    ValuesModified.fromJson(Map<String, dynamic> json) 
        :  super.fromJson(json)
        ,  values = new List.from((json['values'] as List).map((json) => jsonToObj(json) as T));
    
    ValuesModified(List<T> values) : super(name : NAME), values = values {
        json['values'] = new List.from(values.map((T value) => value.json));
    }
}