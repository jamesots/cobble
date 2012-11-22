part of webserver;

abstract class RestHandler {
  onGet(HttpRequest request, HttpResponse response);
  onPost(HttpRequest request, HttpResponse response);
  onPut(HttpRequest request, HttpResponse response);
  onDelete(HttpRequest request, HttpResponse response);
  methodNotImplemented(HttpRequest request, HttpResponse response);
  forbidden(HttpRequest request, HttpResponse response);
  bool authenticated(HttpRequest request, HttpResponse response);
}

