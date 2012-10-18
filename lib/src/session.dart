part of webserver;

class SessionManager {
  Map<String, Session> _sessions;
  Math.Random _random;
  Duration _timeout;
  
  SessionManager() {
    _sessions = new Map<String, Session>();
    _random = new Math.Random(new Date.now().millisecondsSinceEpoch);
    timeout = 1;
  }
  
  void set timeout(int minutes) {
    _timeout = new Duration(minutes: minutes);
  }
  
  int get timeout => _timeout.inMinutes;
  
  String _generateId() {
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
  
  Session createSession(String remoteHost) {
    String id = _generateId();
    
    Session session = new Session._internal(id);
    _sessions["$remoteHost/$id"] = session;
    return session;
  }
  
  Session findSession(String remoteHost, String id) {
    expireSessions();
    var session = _sessions["$remoteHost/$id"];
    if (session != null) {
      _updateAccessTime(session);
    }
    return session;
  }
  
  void expireSessions() {
    var oldestTime = new Date.now();
    oldestTime = oldestTime.subtract(_timeout);
    _sessions.forEach((key, session) {
      if (session._accessed < oldestTime) {
        _sessions.remove(key);
        // TODO have an event when a session is expired?
      };
    });
  }
  
  void _updateAccessTime(Session session) {
    session._accessed = new Date.now();
  }
}

class Session {
  Map values;
  String _id;
  Date _accessed;
  
  String get id => _id;
  
  Session._internal(String id) {
    values = new Map();
    _id = id;
    _accessed = new Date.now();
  }
  
  Date lastAccessed => _accessed;
}
