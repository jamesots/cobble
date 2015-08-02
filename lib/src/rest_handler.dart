part of cobble;

class _AuthRequired {
  bool GET;
  bool POST;
  bool PUT;
  bool DELETE;

  _AuthRequired(bool this.GET, bool this.POST, bool this.PUT, bool this.DELETE);
  
  bool requiredFor(String method) {
    switch (method) {
      case "GET":
        return GET;
      case "PUT":
        return PUT;
      case "POST":
        return POST;
      case "DELETE":
        return DELETE;
      default:
        return false;
    }
  }
}

/**
 * Override [RestHandler] to handle REST requests. See [Server.mapRestHandlers].
 */
abstract class RestHandler extends RequestHandler {
  _AuthRequired _authRequired;

  /**
   * If authentication is required for any REST methods, specify it here.
   * If it is required, [checkAuthenticated] will be called before allowing the
   * request to continue.
   */
  RestHandler([bool getAuthRequired=true, bool postAuthRequired=true, bool putAuthRequired=true, bool deleteAuthRequired=true]) {
      _authRequired = new _AuthRequired(getAuthRequired, postAuthRequired, putAuthRequired, deleteAuthRequired);
    }

  /**
   * Sends a NOT_IMPLEMENTED (501) response.
   */
  methodNotImplemented(HttpRequest request) {
    request.response.statusCode = HttpStatus.NOT_IMPLEMENTED;
    request.response.reasonPhrase = "Method not implemented: ${request.method}";
  }

  /**
   * This should not be overridden. It works out which method handler to
   * call.
   */
  onRequest(HttpRequest request, HttpResponse response) async {
    if (!authenticated(request)) {
      forbidden(request);
    } else {
      response.headers.add("Content-Type", "application/json");
      try {
        switch (request.method) {
          case "GET":
            var objects = await onGet(request);
            _writeJsonResponse(response, objects);
            break;
          case "POST":
            var json = await _decodeJsonRequest(request);
            var objects = await onPost(request, json);
            _writeJsonResponse(response, objects);
            break;
          case "PUT":
            var json = await _decodeJsonRequest(request);
            var objects = await onPut(request, json);
            _writeJsonResponse(response, objects);
            break;
          case "DELETE":
            var json = await _decodeJsonRequest(request);
            var objects = await onDelete(request, json);
            _writeJsonResponse(response, objects);
            break;
          default:
            methodNotImplemented(request);
        }
      } catch (e) {
        serverError(request, e);
        _writeJsonResponse(response, {
          "exception": e.toString()
        });
      }
    }
  }

  _decodeJsonRequest(HttpRequest request) async {
    var jsonString = await request.transform(UTF8.decoder).join();
    return JSON.decode(jsonString);
  }

  _writeJsonResponse(HttpResponse response, json) {
    response.write(JSON.encode(json));
    response.close();
  }

  /**
   * If you want to use authentication, you must override this method. It is called
   * whenever a request comes in which was specified as requiring authentication
   * in the constructor.
   */
  bool checkAuthenticated(HttpRequest request);

  /**
   * Returns [true] if the request is authenticated or doesn't require authentication,
   * [false] otherwise.
   */
  bool authenticated(HttpRequest request) {
    if (_authRequired.requiredFor(request.method)) {
      return checkAuthenticated(request);
    }
    return true;
  }

  /**
   * Sends a FORBIDDEN (403) response.
   */
  void forbidden(HttpRequest request) {
    request.response.statusCode = HttpStatus.FORBIDDEN;
    request.response.reasonPhrase = "Forbidden";
  }

  /**
   * Sends a METHOD_NOT_ALLOWED (405) response.
   */
  void notAllowed(HttpRequest request) {
    request.response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
    request.response.reasonPhrase = "Method not allowed: ${request.method}";
  }

  void success(HttpRequest request) {
    request.response.statusCode = HttpStatus.OK;
    request.response.reasonPhrase = "Success";
  }

  void conflict(HttpRequest request) {
    request.response.statusCode = HttpStatus.CONFLICT;
    request.response.reasonPhrase = "Conflict";
  }

  void serverError(HttpRequest request, e) {
    request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    request.response.reasonPhrase = "Internal server error";
  }

  /**
   * Override this to handle GET requests.
   *
   * Return a [Map] which will be returned as JSON to the client.
   *
   * Sends a METHOD_NOT_ALLOWED response by default.
   */
  Map onGet(HttpRequest request) async {
    notAllowed(request);
  }

  /**
   * Override this to handle POST requests.
   *
   * The body of the request is converted into [json] objects.
   *
   * Return a [Map] which will be returned as JSON to the client.
   *
   * Sends a METHOD_NOT_ALLOWED response by default.
   */
   Map onPost(HttpRequest request, dynamic json) async {
    notAllowed(request);
  }

  /**
   * Override this to handle PUT requests.
   *
   * The body of the request is converted into [json] objects.
   *
   * Return a [Map] which will be returned as JSON to the client.
   *
   * Sends a METHOD_NOT_ALLOWED response by default.
   */
  Map onPut(HttpRequest request, dynamic json) async {
    notAllowed(request);
  }

  /**
   * Override this to handle DELETE requests.
   *
   * The body of the request is converted into [json] objects.
   *
   * Return a [Map] which will be returned as JSON to the client.
   *
   * Sends a METHOD_NOT_ALLOWED response by default.
   */
  Map onDelete(HttpRequest request, dynamic json) async {
    notAllowed(request);
  }
}
