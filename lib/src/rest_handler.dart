part of webserver;

class _AuthRequired {
  bool GET;
  bool POST;
  bool PUT;
  bool DELETE;

  _AuthRequired(this.GET, this.POST, this.PUT, this.DELETE);
}

abstract class RestHandler extends WrappedRequestHandler {
  _AuthRequired _authRequired;
  
  RestHandler([bool getAuthRequired=true, bool postAuthRequired=true, bool putAuthRequired=true, bool deleteAuthRequired=true]) :
    super() {
      _authRequired = new _AuthRequired(getAuthRequired, postAuthRequired, putAuthRequired, deleteAuthRequired);
    }
  
  onRequest(HttpRequest request, HttpResponse response) {
    response.headers.add("Content-Type", "application/json");
    switch (request.method) {
      case "GET": 
        if (!_authRequired.GET || authenticated(request, response)) {
          onGet(request, response);
        }
        break;
      case "POST": 
        if (!_authRequired.POST || authenticated(request, response)) {
          onPost(request, response);
        }
        break;
      case "PUT": 
        if (!_authRequired.PUT || authenticated(request, response)) {
          onPut(request, response);
        }
        break;
      case "DELETE": 
        if (!_authRequired.DELETE || authenticated(request, response)) {
          onDelete(request, response);
        }
        break;
      default:
        methodNotImplemented(request, response);
    }
  }

  bool authenticated(HttpRequest request, HttpResponse response) {
    return true;
    //forbidden(request, response);
    //return false;
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
  
  void methodNotImplemented(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.NOT_IMPLEMENTED;
    response.reasonPhrase = "Method not implemented: ${request.method}";
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
