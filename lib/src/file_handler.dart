part of webserver;

class FileHandler implements RequestHandler {
  String _path;
  String _trim;
  FileHandler(String path, {String trim}) {
    _path = path;
    _trim = trim;
  }
  
  RequestHandlerMethod _notFoundHandler;
  RequestHandlerMethod _forbiddenHandler;
  
  RequestHandlerMethod get notFoundHandler => _notFoundHandler;
                        set notFoundHandler(var value) => _notFoundHandler = value;
  
  RequestHandlerMethod get forbiddenHandler => _forbiddenHandler;
                        set forbiddenHandler(var value) => _forbiddenHandler = value;
  
  onRequest(HttpRequest request, HttpResponse response) {
    var path = request.uri.path;
    if (_trim != null && path.startsWith(_trim)) {
      path = path.substring(_trim.length);
    }
    String newPath = "${_path}${path}";
    File file = new File(newPath);
    if (!file.existsSync()) {
      print("File doesn't exist: ${newPath}");
      if (_notFoundHandler != null) {
        _notFoundHandler(request, response);
      } else {
        response.statusCode = HttpStatus.NOT_FOUND;
        response.write("Not found!");
        response.close();
      }
      return;
    }
    String filePath = file.absolute.path;
    
    if (!filePath.startsWith(_path)) {
      print("Trying to load file outsite of file directory: ${file.absolute.path}");
      if (_forbiddenHandler != null) {
        _forbiddenHandler(request, response);
      } else {
        response.statusCode = HttpStatus.FORBIDDEN;
        response.write("Go away!");
        response.close();
      }
    } else {
      response.statusCode = HttpStatus.OK;
      
      response.addStream(file.openRead()).then((_) {
        response.close();
      });
    }
  }
}
