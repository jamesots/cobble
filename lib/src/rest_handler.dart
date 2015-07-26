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
  methodNotImplemented(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.NOT_IMPLEMENTED;
    response.reasonPhrase = "Method not implemented: ${request.method}";
    response.close();
  }

  /**
   * This should not be overridden.
   */
  void onRequest(HttpRequest request, HttpResponse response) {
    throw "onRequest should not be called on a RestHandler";
  }

  /**
   * If you want to use authentication, you must override this method. It is called
   * whenever a request comes in which was specified as requiring authentication
   * in the constructor.
   */
  bool checkAuthenticated(HttpRequest request, HttpResponse response);

  /**
   * Returns [true] if the request is authenticated or doesn't require authentication,
   * [false] otherwise.
   */
  bool authenticated(HttpRequest request, HttpResponse response) {
    if (_authRequired.requiredFor(request.method)) {
      return checkAuthenticated(request, response);
    }
    return true;
  }

  /**
   * Sends a FORBIDDEN (403) response.
   */
  void forbidden(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.FORBIDDEN;
    response.reasonPhrase = "Forbidden";
    response.close();
  }

  /**
   * Sends a METHOD_NOT_ALLOWED (405) response.
   */
  void notAllowed(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
    response.reasonPhrase = "Method not allowed: ${request.method}";
    response.close();
  }

  /**
   * Override this to handle GET requests. Sends a METHOD_NOT_ALLOWED response by default.
   */
  onGet(HttpRequest request, HttpResponse response) {
    notAllowed(request, response);
  }

  /**
   * Override this to handle POST requests. Sends a METHOD_NOT_ALLOWED response by default.
   */
  onPost(HttpRequest request, HttpResponse response) {
    notAllowed(request, response);
  }

  /**
   * Override this to handle PUT requests. Sends a METHOD_NOT_ALLOWED response by default.
   */
  onPut(HttpRequest request, HttpResponse response) {
    notAllowed(request, response);
  }

  /**
   * Override this to handle DELETE requests. Sends a METHOD_NOT_ALLOWED response by default.
   */
  onDelete(HttpRequest request, HttpResponse response) {
    notAllowed(request, response);
  }
}
