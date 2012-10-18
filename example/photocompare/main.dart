import 'package:dartwebserver/webserver.dart';
import 'dart:io';
import 'dart:math' as Math;

class NotFoundHandler implements WrappedRequestHandler {
  onRequest(HttpRequestWrapper request, HttpResponseWrapper response) {
    response.outputStream.writeString("""
NOT FOUND
""");
    response.outputStream.close();
  }
}

class TheHandler implements WrappedRequestHandler {
  Math.Random rnd;
  String _path;
  
  TheHandler(this._path) {
    rnd = new Math.Random(new Date.now().millisecondsSinceEpoch);
  }
  
  onRequest(HttpRequestWrapper request, HttpResponseWrapper response) {
    print("request received");
    response.statusCode = HttpStatus.OK;

    Session session = request.session;
    if (request.session == null) {
      session = response.createSession();
      // look up existing files
      var dir = new Directory(_path);
      var list = dir.list();
      var files = [];
      list.onFile = (filename) {
        var f = filename.substring(filename.lastIndexOf("/"));
        files.add(f);
      };
      list.onDone = (completed) {
        session.values["files"] = files;
        session.values["left"] = 0;
        session.values["right"] = 1;
        var prefs = [];
        prefs.insertRange(0, files.length, 0);
        session.values["prefs"] = prefs;
        calcPage(request, response, session);
      };
      print("creating session");
    } else {
      calcPage(request, response, session);
    }
  }
  
  calcPage(HttpRequestWrapper request, HttpResponseWrapper response, Session session) {
    Map<String, dynamic> values = session.values;
    print("got session");
    List<String> files = values["files"];
    int left = values["left"];
    int right = values["right"];
    if (request.queryParameters["pref"] != null) {
      try {
        var pref = int.parse(request.queryParameters["pref"]);
        if (pref == 1) {
          values["prefs"][left]++;
        }
        if (pref == 2) {
          values["prefs"][right]++;
        }
        right++;
        if (right == files.length) {
          left++;
          if (left == files.length - 1) {
            showResult(response, session);
            return;
          }
          right = left + 1;
        }
      } on FormatException catch (e) {
      }
    }
    values["left"] = left;
    values["right"] = right;
    var image1 = files[left];
    var image2 = files[right];
    showPage(response, image1, image2);
  }
  
  showResult(HttpResponseWrapper response, Session session) {
    var values = session.values;
    var maxval = 0;
    var maxitem = 0;
    for (var i = 0; i < values["prefs"].length; i++) {
      if (values["prefs"][i] > maxval) {
        maxval = values["prefs"][i];
        maxitem = i;
      }
    }
    var image = values["files"][maxitem];
    response.outputStream.writeString("""
<html>
<head>
<title>Photo Compare</title>
</head>
<body>
<h1>Photo Compare</h1>
<p>Winning image</p>
<img src="${image}"/><br />
</body>
</html>
""");
    response.outputStream.close();
  }
  
  showPage(HttpResponseWrapper response, String image1, String image2) {
    response.outputStream.writeString("""
<html>
<head>
<title>Photo Compare</title>
</head>
<body>
<h1>Photo Compare</h1>
<p>Image 1</p>
<img src="${image1}"/><br />
<p>Image 2</p>
<img src="${image2}"/><br />
<form action="/">
Which image do you prefer?
<input name="pref" />
</form>
</body>
</html>
""");
    response.outputStream.close();
  }
}

void main() {
  var server = new Server();
  var notFoundHandler = new NotFoundHandler();

  File here = new File(".");
  String herePath = here.fullPathSync();
  print("here: $herePath");
  String newPath = "${herePath}/example/photocompare/files";
  var fileHandler = new FileHandler(newPath);
  fileHandler.notFoundHandler = notFoundHandler;
  var handler = new TheHandler(newPath);
  
  server.listen('127.0.0.1', 8081);
  server.defaultRequestHandler = notFoundHandler;
  
  server.mapRequestHandlers({
    r"^/$": handler,
    r"\.(png|txt|gif|html|jpg)$": fileHandler
  });
}
