// TODO session expiry
// TODO lock session to host



class SessionManager {
  Map<String, Session> _sessions;
  Math.Random _random;
  
  SessionManager() {
    _sessions = new Map<String, Session>();
    _random = new Math.Random(new Date.now().millisecondsSinceEpoch);
  }
  
  String generateId() {
    String id;
    do {
      StringBuffer sb = new StringBuffer();
      for (int i = 0; i < 15; i++) {
        int charCode = _random.nextInt(26) + 65;
        sb.addCharCode(charCode);
      }
      id = sb.toString();
    } while (_sessions.containsKey(id));
    return id;
  }
  
  Session createSession() {
    String id = generateId();
    
    Session session = new Session._internal(id);
    _sessions[id] = session;
    return session;
  }
  
  Session findSession(String id) {
    return _sessions[id];
  }
}

class Session {
  Map values;
  String _id;
  
  String get id => _id;
  
  Session._internal(String id) {
    values = new Map();
    _id = id;
  }
}
