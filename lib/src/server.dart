part of webserver;

abstract class WrappedRequestHandler {
  void onRequest(HttpRequestWrapper request, HttpResponseWrapper response);
}

class Server {
  HttpServer _server;
  SessionManager _sessionManager;
  
  Server() {
    _server = new HttpServer();
    _sessionManager = new SessionManager();
  }
  
  void listen(String host, int port) {
    _server.listen(host, port);
  }
  
  void addRequestHandler(bool matcher(HttpRequest request), Object handler) {
    _server.addRequestHandler(matcher, (HttpRequest request, HttpResponse response) {
      print("handling request with wrapped handler, path: ${request.path}");
      if (handler is WrappedRequestHandler) {
        WrappedRequestHandler wrappedHandler = handler;
        wrappedHandler.onRequest(new HttpRequestWrapper._wrap(request, _sessionManager), new HttpResponseWrapper._wrap(response, _sessionManager, request.connectionInfo.remoteHost));
      } else {
        handler(new HttpRequestWrapper._wrap(request, _sessionManager), new HttpResponseWrapper._wrap(response, _sessionManager, request.connectionInfo.remoteHost));        
      }
    });
  }
  
  void mapRequestHandlers(Map<String, Object> map) {
    for (dynamic key in map.getKeys()) {
      RegExp re = new RegExp(key);
      addRequestHandler((HttpRequest request) {
        var matches = re.hasMatch(request.path);
        print("checking ${request.path} against $key, matches: $matches");
        return matches;
      }, map[key]);
    }
  }
  
  void mapRequestHandlersForMimeType(String mimeType, Map<String, Object> map) {
    for (dynamic key in map.getKeys()) {
      RegExp re = new RegExp(key);
      addRequestHandler((HttpRequest request) {
        var accepts = request.headers['Accept'];
        if (accepts == null) {
          return false;
        }
        for (var accept in accepts) {
          //TODO this is crude
          if (accept.contains(mimeType)) {
            var matches = re.hasMatch(request.path);
            print("checking ${request.path} against $key, matches: $matches");
            return matches;
          }
        }
        return false;
      }, map[key]);
    }
  }
  
  void set defaultRequestHandler(Object handler) {
    _server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
      print("handling request with default wrapped handler, path: ${request.path}");
      if (handler is WrappedRequestHandler) {
        WrappedRequestHandler wrappedHandler = handler;
        wrappedHandler.onRequest(new HttpRequestWrapper._wrap(request, _sessionManager), new HttpResponseWrapper._wrap(response, _sessionManager, request.connectionInfo.remoteHost));
      } else {
        handler(new HttpRequestWrapper._wrap(request, _sessionManager), new HttpResponseWrapper._wrap(response, _sessionManager, request.connectionInfo.remoteHost));        
      }
    };
  }
}