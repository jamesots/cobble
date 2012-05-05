class HttpResponseWrapper implements HttpResponse {
  HttpResponse _response;
  SessionManager _sessionManager;
  Session _session;
  
  Session get session() => _session;
  
  HttpResponseWrapper.wrap(HttpResponse response, SessionManager sessionManager) {
    _response = response;
    _sessionManager = sessionManager;
  }
  
  Session createSession() {
    Session session = _sessionManager.createSession();
    _response.headers.add("Set-Cookie", "DARTSESSION=${session.id}");
    _session = session;
    return session;
  }
  
  HttpHeaders get headers() => _response.headers;
  
  OutputStream get outputStream() => _response.outputStream;
  
  int get contentLength() => _response.contentLength;
      set contentLength(int value) => _response.contentLength = value;
      
  String get reasonPhrase() => _response.reasonPhrase;
         set reasonPhrase(String value) => _response.reasonPhrase = value;
         
  int get statusCode() => _response.statusCode;
      set statusCode(int value) => _response.statusCode = value;
}
