part of webserver;

abstract class WrappedRequestHandler {
  void onRequest(HttpRequest request, HttpResponse response);
}

class Server {
  HttpServer _server;
  
  Server() {
    _server = new HttpServer();
  }
  
  void listen(String host, int port) {
    _server.listen(host, port);
  }
  
  void addRequestHandler(bool matcher(HttpRequest request), Object handler) {
    _server.addRequestHandler(matcher, (HttpRequest request, HttpResponse response) {
      try {
        print("handling request with wrapped handler, path: ${request.path}");
        if (handler is WrappedRequestHandler) {
          WrappedRequestHandler wrappedHandler = handler;
          wrappedHandler.onRequest(request, response);
        } else {
          handler(request, response);        
        }
      } catch (e) {
        systemError(response, e);
      }
    });
  }
  
  void mapRequestHandlers(Map<String, Object> map) {
    for (var key in map.keys) {
      RegExp re = new RegExp(key);
      addRequestHandler((HttpRequest request) {
        var matches = re.hasMatch(request.path);
        print("checking ${request.path} against $key, matches: $matches");
        return matches;
      }, map[key]);
    }
  }
  
  void mapRequestHandlersForMimeType(String mimeType, Map<String, Object> map) {
    for (var key in map.keys) {
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
      try {
        print("handling request with default wrapped handler, path: ${request.path}");
        if (handler is WrappedRequestHandler) {
          WrappedRequestHandler wrappedHandler = handler;
          wrappedHandler.onRequest(request, response);
        } else {
          handler(request, response);        
        }
      } catch (e) {
        systemError(response, e);
      }
    };
  }

  void systemError(HttpResponse response, dynamic e) {
    print("Error handling request: ${e}");
    try {
      response.outputStream.write("Error handling request: ${e}");
    } catch (ee) {
      print("Can't write to stream: $ee");
    }
    try {
      response.outputStream.close();
    } catch (ee) {
      print("Can't close stream: $ee");
    }
  }
}
