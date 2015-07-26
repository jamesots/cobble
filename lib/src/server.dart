part of cobble;

abstract class RequestHandler {
  void onRequest(HttpRequest request, HttpResponse response);
}

/**
 * Handles a [request]. [response] is already available as request.response, but
 * is provided as an argument to the request handler for convenience.
 */
typedef dynamic RequestHandlerMethod(HttpRequest request, HttpResponse response);

/**
 * Not currently used
 */
typedef dynamic ErrorHandlerMethod(HttpRequest request, HttpResponse response, var error);

/**
 * Returns true if the request handler should handle the [request], false otherwise.
 */
typedef bool Matcher(HttpRequest request);

/**
 * A simple web server.
 */
class Server {
  HttpServer _server;
  ErrorHandlerMethod _errorHandler;
  Map<Matcher, RequestHandlerMethod> _handlers;
  RequestHandlerMethod _defaultHandler;
  
  Server() {
    _handlers = new Map<Matcher, RequestHandlerMethod>();
  }

  /**
   * Listen on the given [host] and [port]. For how these arguments are used,
   * see [HttpServer.bind]
   */
  Future listen(String host, int port) {
    return HttpServer.bind(host, port).then((server) {
      _server = server;
      server.listen(handleRequest);
    });
  }

  /**
   * Add a request handler. When deciding whether to use a particular handler,
   * the [matcher] is first called. Only if it returns true is the [handler] called.
   *
   * Matchers are called in the order they were added.
   */
  addRequestHandler(Matcher matcher, RequestHandlerMethod handler) {
    _handlers[matcher] = handler;
  }

  /**
   * The [defaultRequestHandler] is called if no other handler matches the request.
   */
  set defaultRequestHandler(RequestHandlerMethod handler) => _defaultHandler = handler;
  RequestHandlerMethod get defaultRequestHandler => _defaultHandler;

  /**
   * Handles the HTTP request. If [listen] has been called, this is called internally whenever
   * an HTTP request arrives. If you are using Google App Engine you can pass this
   * method to runAppEngine.
   */
  void handleRequest(HttpRequest request) {
    runZoned(() {
      _handlers.keys.firstWhere((matcher) {
        if (matcher(request)) {
          _handlers[matcher](request, request.response);
          return true;
        }
        return false;
      }, orElse: () {
        _defaultHandler(request, request.response);
      });
    }, onError: (e, s) {
      print("Exception while handling request: $e\n$s");
    });
  }

  /**
   * Maps request handlers to regular expressions. The regular expressions
   * are matched against request.uri.path, and if it matches then the
   * mapped request handler is called.
   *
   * The order in which the handlers are called depends on the map
   * implementation used. Dart's default map literal preserves insertion order.
   */
  void mapRequestHandlers(Map<String, RequestHandlerMethod> map) {
    for (var key in map.keys) {
      RegExp re = new RegExp(key);
      addRequestHandler((HttpRequest request) {
        var matches = re.hasMatch(request.uri.path);
        print("checking ${request.uri.path} against $key, matches: $matches");
        return matches;
      }, map[key]);
    }
  }

  /**
   * Maps rest handlers to regular expressions. If the request is a REST request
   * and request.uri.path matches the regular expression, then the
   * mapped request handler is called.
   *
   * A REST request is defined thusly:
   *  - Any request whose method is DELETE.
   *  - Any GET or HEAD request where the Accept header is application/json
   *  - Any PUT or POST request where the Content-Type header is application/json
   *
   * The order in which the handlers are called depends on the map
   * implementation used. Dart's default map literal preserves insertion order.
   */
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

  RequestHandlerMethod _getRestHandler(RestHandler restHandler) {
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

  /**
   * Not currently used
   */
  void set errorHandler(ErrorHandlerMethod handler) {
    _errorHandler = handler;
  }

  /**
   * Not currently used
   */
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
