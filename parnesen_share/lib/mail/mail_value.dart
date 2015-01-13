part of mail_share;

abstract class Value {
    /** the underlying json contains all of the message's (and it's subclass') state **/
    final Map<String, dynamic> json;
    
    Value.fromJson(Map<String, dynamic> json) : this.json = json;
}