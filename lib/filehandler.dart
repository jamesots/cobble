class FileHandler implements WrappedRequestHandler {
  String _path;
  FileHandler(String path) {
    _path = path;
  }
  
  WrappedRequestHandler _notFoundHandler;
  WrappedRequestHandler _forbiddenHandler;
  
  WrappedRequestHandler get notFoundHandler() => _notFoundHandler;
                        set notFoundHandler(var value) => _notFoundHandler = value;
  
  WrappedRequestHandler get forbiddenHandler() => _forbiddenHandler;
                        set forbiddenHandler(var value) => _forbiddenHandler = value;
  
  onRequest(HttpRequestWrapper request, HttpResponseWrapper response) {
    String newPath = "${_path}${request.path}";
    File file = new File(newPath);
    if (!file.existsSync()) {
      print("File doesn't exist: ${newPath}");
      if (_notFoundHandler != null) {
        _notFoundHandler.onRequest(request, response);
      } else {
        response.statusCode = HttpStatus.NOT_FOUND;
        response.outputStream.writeString("Not found!");
        response.outputStream.close();
      }
      return;
    }
    String filePath = file.fullPathSync();
    
    if (!filePath.startsWith(_path)) {
      print("Trying to load file outsite of file directory: ${file.fullPathSync()}");
      if (_forbiddenHandler != null) {
        _forbiddenHandler.onRequest(request, response);
      } else {
        response.statusCode = HttpStatus.FORBIDDEN;
        response.outputStream.writeString("Go away!");
        response.outputStream.close();
      }
    } else {
      response.statusCode = HttpStatus.OK;
      
      file.openInputStream().pipe(response.outputStream);
    }
  }
}
