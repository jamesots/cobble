part of webserver;

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

abstract class RestHandler extends WrappedRequestHandler {
  _AuthRequired _authRequired;

  RestHandler([bool getAuthRequired=true, bool postAuthRequired=true, bool putAuthRequired=true, bool deleteAuthRequired=true]) {
      _authRequired = new _AuthRequired(getAuthRequired, postAuthRequired, putAuthRequired, deleteAuthRequired);
    }
    
  methodNotImplemented(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.NOT_IMPLEMENTED;
    response.reasonPhrase = "Method not implemented: ${request.method}";
    response.outputStream.close();
  }
  
  void onRequest(HttpRequest request, HttpResponse response) {
    throw "onRequest should not be called on a RestHandler";
  }

  bool checkAuthenticated(HttpRequest request, HttpResponse response);

  bool authenticated(HttpRequest request, HttpResponse response) {
    if (_authRequired.requiredFor(request.method)) {
      return checkAuthenticated(request, response);
    }
    return true;
  }
  
  void forbidden(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.FORBIDDEN;
    response.reasonPhrase = "Forbidden";
    response.outputStream.close();
  }
  
  void notAllowed(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
    response.reasonPhrase = "Method not allowed: ${request.method}";
    response.outputStream.close();
  }
  
  onGet(HttpRequest request, HttpResponse response) {
    notAllowed(request, response);
  }
  onPost(HttpRequest request, HttpResponse response) {
    notAllowed(request, response);
  }
  onPut(HttpRequest request, HttpResponse response) {
    notAllowed(request, response);
  }
  onDelete(HttpRequest request, HttpResponse response) {
    notAllowed(request, response);
  }
  
  Future<String> readAll(HttpRequest request) {
    var completer = new Completer<String>();
    var payloadStream = new StringInputStream(request.inputStream);
    var payload = new StringBuffer();
    payloadStream.onLine = () {
      var line;
      while ((line = payloadStream.readLine()) != null) {
        payload.add(line);
      }
    };
    payloadStream.onClosed = () {
      completer.complete(payload.toString());
    };
    return completer.future;
  }
}
