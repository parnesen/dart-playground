library parnesen_util;

import 'package:quiver/check.dart';


bool isSet(String str) => str != null && str.trim().isNotEmpty;

final Map<String, String> config = {};


String checkNotEmpty(String str, {String message}) {
    checkState(isSet(str), message: message);
    return str;
}

const Nullable nullable = const Nullable();
class Nullable { const Nullable(); }

const NonNull nonNull = const NonNull();
class NonNull { const NonNull(); }


/** a mixin for classes that have keys **/
abstract class KeyedValue<K> {
    K get key;
}

String toCommaSeperatedString(final List values, {bool useQuotes : false, String stringify(dynamic value)}) {
    var toString = stringify != null ? stringify : (dynamic value) => value == null ? 'null' : value.toString();
    
    final int lastIndex = values.length - 1;
    final StringBuffer strBuf = new StringBuffer();
    for(int ii = 0; ii < values.length; ii++) {
        String str = toString(values[ii]);
        strBuf.write(useQuotes ? "'$str'" : str);
        if(ii != lastIndex) {
            strBuf.write(", ");
        }
    }
    return strBuf.toString();
}


class InitStatus {
    
    static const InitStatus uninitialized = const InitStatus._create("uninitialized", 0);
    static const InitStatus initializing  = const InitStatus._create("initializing", 1);
    static const InitStatus initialized   = const InitStatus._create("initialized", 2);
    
    final String status;
    final int order;
    
    bool get isUninitialized => this == uninitialized;
    bool get isInitialized   => this == initialized;
    bool get isInitializing  => this == initializing;
    
    const InitStatus._create(this.status, this.order);
}
