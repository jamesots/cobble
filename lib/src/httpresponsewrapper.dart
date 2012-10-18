part of webserver;

//TODO add expiry time to cookies
//TODO host only cookies? what are they?

class HttpResponseWrapper implements HttpResponse {
  HttpResponse _response;
  SessionManager _sessionManager;
  Session _session;
  String _remoteHost;
  
  Session get session => _session;
  
  DetachedSocket detachSocket() => _response.detachSocket();
  
  HttpResponseWrapper._wrap(HttpResponse response, SessionManager sessionManager, String remoteHost) {
    _response = response;
    _sessionManager = sessionManager;
    _remoteHost = remoteHost;
  }
  
  Session createSession() {
    Session session = _sessionManager.createSession(_remoteHost);
    _response.headers.add("Set-Cookie", "DARTSESSION=${session.id}");
    _session = session;
    return session;
  }
  
  HttpHeaders get headers => _response.headers;
  
  OutputStream get outputStream => _response.outputStream;
  
  int get contentLength => _response.contentLength;
      set contentLength(int value) => _response.contentLength = value;
      
  String get reasonPhrase => _response.reasonPhrase;
         set reasonPhrase(String value) => _response.reasonPhrase = value;
         
  int get statusCode => _response.statusCode;
      set statusCode(int value) => _response.statusCode = value;
      
  bool get persistentConnection => _response.persistentConnection;
  
  List<Cookie> get cookies => _response.cookies;
  
  HttpConnectionInfo get connectionInfo => _response.connectionInfo;
}
