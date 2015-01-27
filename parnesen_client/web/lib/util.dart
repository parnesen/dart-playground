library parnesen_util;

import 'package:quiver/check.dart';


bool isSet(String str) => str != null && str.trim().isNotEmpty;

final Map<String, String> config = {};


String checkIsSet(String str, {String message}) {
    checkState(isSet(str), message: message);
    return str;
}

const Nullable nullable = const Nullable();
class Nullable { const Nullable(); }

const NonNull nonNull = const NonNull();
class NonNull { const NonNull(); }

