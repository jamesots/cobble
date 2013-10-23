part of webserver;

abstract class WrappedRequestHandler {
  void onRequest(HttpRequest request, HttpResponse response);
}

typedef void RequestHandler(HttpRequest request, HttpResponse response);

typedef void ErrorHandler(HttpRequest request, HttpResponse response, var error);

typedef bool Matcher(HttpRequest request);

class Server {
  HttpServer _server;
  ErrorHandler _errorHandler;
  Map<Matcher, WrappedRequestHandler> _handlers;
  WrappedRequestHandler _defaultHandler;
  
  Server() {
    _handlers = new Map<Matcher, Object>();
  }
  
  Future listen(String host, int port) {
    return HttpServer.bind(host, port).then((server) {
      _server = server;
      server.listen(handleRequest);
    });
  }
  
  addRequestHandler(Matcher matcher, Object handler) {
    _handlers[matcher] = handler;
  }
  
  set defaultRequestHandler(Object handler) => _defaultHandler = handler;
  Object get defaultRequestHandler => _defaultHandler;
  
  RequestHandler _getCheckedRequestHandler(Object handler) {
    RequestHandler method = _getHandlerMethod(handler);
    return (HttpRequest request, HttpResponse response) {
      try {
        print("handling request, path: ${request.uri.path}");
        method(request, response);
      } catch (e) {
        handleError(request, response, e);
      }
    };
  }
  
  RequestHandler _getHandlerMethod(Object handler) {
    RequestHandler method;
    if (handler is WrappedRequestHandler) {
      method = (handler as WrappedRequestHandler).onRequest;
    } else if (handler is RequestHandler) {
      method = handler;
    } else {
      throw "handler must be a WrappedRequestHandler or a RequestHandler";
    }
    return method;
  }
  
  void handleRequest(HttpRequest request) {
    _handlers.keys.firstWhere((matcher) {
      if (matcher(request)) {
        _handlers[matcher].onRequest(request, request.response);
        return true;
      }
      return false;
    }, orElse: () {
      _defaultHandler.onRequest(request, request.response);
    });
  }
  
  void mapRequestHandlers(Map<String, Object> map) {
    for (var key in map.keys) {
      RegExp re = new RegExp(key);
      addRequestHandler((HttpRequest request) {
        var matches = re.hasMatch(request.uri.path);
        print("checking ${request.uri.path} against $key, matches: $matches");
        return matches;
      }, map[key]);
    }
  }
  
  void mapRestHandlers(Map<String, RestHandler> map) {
    for (var key in map.keys) {
      var matcher = _getRestMatcher(key);
      var handler = _getRestHandler(map[key]);
      addRequestHandler(matcher, handler);
    }
  }

  Matcher _getRestMatcher(key) {
    RegExp re = new RegExp(key);
    return (HttpRequest request) {
      if (request.method == "DELETE") {
        var matches = re.hasMatch(request.uri.path);
        print("checking ${request.uri.path} against $key, matches: $matches");
        return matches;
      }
      var header;
      if (request.method == "GET" || request.method == "HEAD") {
        header = "Accept";
      } else if (request.method == "PUT" || request.method == "POST") {
        header = "Content-Type";
      }
      if (header == null) {
        return false;
      }
      var value = request.headers[header];
      if (value == null) {
        return false;
      }
      for (var accept in value) {
        //TODO this is crude, see http://www.xml.com/pub/a/2005/06/08/restful.html
        if (accept.contains('application/json')) {
          var matches = re.hasMatch(request.uri.path);
          print("checking ${request.uri.path} against $key, matches: $matches");
          return matches;
        }
      }
      return false;
    };
  }

  RequestHandler _getRestHandler(RestHandler restHandler) {
    return (HttpRequest request, HttpResponse response) {
      if (!restHandler.authenticated(request, response)) {
        restHandler.forbidden(request, response);
      } else {
        response.headers.add("Content-Type", "application/json");
        switch (request.method) {
          case "GET":
            restHandler.onGet(request, response);
            break;
          case "POST":
            restHandler.onPost(request, response);
            break;
          case "PUT": 
            restHandler.onPut(request, response);
            break;
          case "DELETE": 
            restHandler.onDelete(request, response);
            break;
          default:
            restHandler.methodNotImplemented(request, response);
        }
      }
    };
  }
  
  void set errorHandler(ErrorHandler handler) {
    _errorHandler = handler;
  }
  
  void handleError(HttpRequest request, HttpResponse response, var error) {
    if (_errorHandler == null) {
      _defaultErrorHandler(request, response, error);
    } else {
      try {
        _errorHandler(request, response, error);
      } catch (e) {
        print("Exception while trying to handle error: $e");
        print("Original error: $error");
      }
    }
  }

  void _defaultErrorHandler(HttpRequest request, HttpResponse response, var error) {
    print("Error handling request: ${error}");
    try {
      response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    } catch (e) {
      print("Can't send header to stream: $e");
    }
    try {
      response.write("Error handling request: ${error}");
    } catch (e) {
      print("Can't write to stream: $e");
    }
    try {
      response.close();
    } catch (e) {
      print("Can't close stream: $e");
    }
  }
}
