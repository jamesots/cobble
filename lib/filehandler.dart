class FileHandler implements WrappedRequestHandler {
  String _path;
  FileHandler(String path) {
    _path = path;
  }
  
  onRequest(HttpRequestWrapper request, HttpResponseWrapper response) {
    String newPath = "${_path}${request.path}";
    File file = new File(newPath);
    if (!file.existsSync()) {
      print("File doesn't exist: ${newPath}");
      response.statusCode = HttpStatus.NOT_FOUND;
      response.outputStream.writeString("Not found!");
      response.outputStream.close();
      return;
    }
    String filePath = file.fullPathSync();
    
    if (!filePath.startsWith(_path)) {
      print("Trying to load file outsite of file directory: ${file.fullPathSync()}");
      response.statusCode = HttpStatus.FORBIDDEN;
      response.outputStream.writeString("Go away!");
      response.outputStream.close();
    } else {
      response.statusCode = HttpStatus.OK;
      
      file.openInputStream().pipe(response.outputStream);
    }
  }
}
