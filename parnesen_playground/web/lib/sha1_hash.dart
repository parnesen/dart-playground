library parnesen_hash;

import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'util.dart';

String sha1HashOf(String value) => new Sha1Hash()[value];

/** A default hash with no salt */
final Sha1Hash sha1Hash = new Sha1Hash();

/** The SHA1 hash algo **/
class Sha1Hash {
    
    final String _salt;
    
    Sha1Hash({String salt}) : _salt = salt;
    
    String operator[](String value) {
        checkIsSet(value);
        SHA1 hash = new SHA1();
        hash.add(new Utf8Encoder().convert(_salt != null ? "$_salt$value" : value));
        String hashed = CryptoUtils.bytesToHex(hash.close());
        return hashed;
    }
}

