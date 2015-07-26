part of cobble;

typedef String MimeResolverMethod(File file);

class FileHandler implements RequestHandler {
  String _path;

  String _trim;

  /**
   * Create a FileHandler which serves files from the given [path].
   * If [trim] is specified, then any request URIs must start with
   * that string, which is then removed before trying to find the file.
   */
  FileHandler(String dir, {String trim}) {
    if (!path.isAbsolute(dir)) {
      throw "Path must be absolute: $dir";
    }
    if (!new Directory(dir).existsSync()) {
      throw "Directory must exist: $dir";
    }
    _path = path.normalize(dir);
    if (trim != null) {
      if (!trim.startsWith("/")) {
        throw "Trim must start with /";
      }
      if (!trim.endsWith("/")) {
        throw "Trim must start with /";
      }
    }
    _trim = trim;
  }
  
  RequestHandlerMethod _notFoundHandler;
  RequestHandlerMethod _forbiddenHandler;
  MimeResolverMethod _mimeResolver;
  
  RequestHandlerMethod get notFoundHandler => _notFoundHandler;
                        set notFoundHandler(var value) => _notFoundHandler = value;
  
  RequestHandlerMethod get forbiddenHandler => _forbiddenHandler;
                        set forbiddenHandler(var value) => _forbiddenHandler = value;

  MimeResolverMethod get mimeResolver => _mimeResolver;
                      set mimeResolver(var value) => _mimeResolver = value;

  _fileDoesNotExist(String newPath, HttpRequest request, HttpResponse response) {
    print("File doesn't exist: ${newPath}");
    if (_notFoundHandler != null) {
      _notFoundHandler(request, response);
    } else {
      response.statusCode = HttpStatus.NOT_FOUND;
      response.write("Not found!");
      response.close();
    }
  }

  _fileOutsideOfDirectory(File file, HttpRequest request, HttpResponse response) {
    print("Trying to load file outsite of file directory: ${file.absolute.path}");
    if (_forbiddenHandler != null) {
      _forbiddenHandler(request, response);
    } else {
      response.statusCode = HttpStatus.FORBIDDEN;
      response.write("Go away!");
      response.close();
    }
  }

  String _getMimeType(File file) {
    if (_mimeResolver != null) {
      var mimeType = _mimeResolver(file);
      if (mimeType != null) {
        return mimeType;
      }
    }
    return mime.lookupMimeType(file.path);
  }

  _sendFile(HttpResponse response, File file) {
    response.statusCode = HttpStatus.OK;

    response.headers.set(HttpHeaders.CONTENT_TYPE, _getMimeType(file));
    response.addStream(file.openRead()).then((_) {
      response.close();
    });
  }

  String _getRealPath(HttpRequest request) {
    var path = request.uri.path;
    if (_trim != null && path.startsWith(_trim)) {
      path = path.substring(_trim.length);
    }
    String newPath = "${_path}/${path}";
    return newPath;
  }

  onRequest(HttpRequest request, HttpResponse response) {
    var newPath = _getRealPath(request);
    File file = new File(newPath);
    if (!file.existsSync()) {
      _fileDoesNotExist(newPath, request, response);
      return;
    }
    String filePath = file.absolute.path;

    if (!path.isWithin(_path, file.path)) {
      _fileOutsideOfDirectory(file, request, response);
    } else {
      _sendFile(response, file);
    }
  }
}
