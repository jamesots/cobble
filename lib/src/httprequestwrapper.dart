part of webserver;

class HttpRequestWrapper implements HttpRequest {
  HttpRequest _request;
  SessionManager _sessionManager;
  Session _session;
  
  HttpRequestWrapper._wrap(HttpRequest request, SessionManager sessionManager) {
    _request = request;
    _sessionManager = sessionManager;
    List cookies = request.headers["cookie"];
    if (cookies != null) {
      for (String cookie in cookies) {
        List parts = cookie.split("=");
        if (parts[0] == "DARTSESSION") {
          var remoteHost = request.connectionInfo.remoteHost;
          String id = parts[1];
          _session = sessionManager.findSession(remoteHost, id);
        }
      }
    }
  }

  Session get session => _session;
  
  int get contentLength => _request.contentLength;
  
  HttpHeaders get headers => _request.headers;
  
  InputStream get inputStream => _request.inputStream;
  
  String get method => _request.method;
  
  String get path => _request.path;
  
  Map get queryParameters => _request.queryParameters;
  
  String get queryString => _request.queryString;
  
  String get uri => _request.uri;
  
  bool get persistentConnection => _request.persistentConnection;
  
  List<Cookie> get cookies => _request.cookies;
  
  String get protocolVersion => _request.protocolVersion;
  
  HttpConnectionInfo get connectionInfo => _request.connectionInfo;
}