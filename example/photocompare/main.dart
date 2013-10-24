import 'package:dartwebserver/webserver.dart';
import 'dart:io';
import 'dart:math' as Math;

class NotFoundHandler implements WrappedRequestHandler {
  onRequest(HttpRequest request, HttpResponse response) {
    response.write("""
NOT FOUND
""");
    response.close();
  }
}

class TheHandler implements WrappedRequestHandler {
  Math.Random rnd;
  String _path;
  
  TheHandler(this._path) {
    rnd = new Math.Random(new DateTime.now().millisecondsSinceEpoch);
  }
  
  onRequest(HttpRequest request, HttpResponse response) {
    print("request received");
    response.statusCode = HttpStatus.OK;

    HttpSession session = request.session;
    if (session.isNew) {
      // look up existing files
      var dir = new Directory(_path);
      var files = [];
      dir.list().listen((file) {
        var f = file.absolute.path.substring(file.absolute.path.lastIndexOf("/"));
        if (f.endsWith(".jpg")) {
          files.add(f);
        }
      }, onDone: () {
        session["files"] = files;
        session["left"] = 0;
        session["right"] = 1;
        var prefs = [];
        for (var i = 0; i < files.length; i++) {
          prefs.add(0);
        }
        session["prefs"] = prefs;
        calcPage(request, response, session);
      });
      print("creating session");
    } else {
      calcPage(request, response, session);
    }
  }
  
  calcPage(HttpRequest request, HttpResponse response, HttpSession session) {
    print("got session");
    List<String> files = session["files"];
    int left = session["left"];
    int right = session["right"];
    if (request.uri.queryParameters["pref"] != null) {
      try {
        var pref = int.parse(request.uri.queryParameters["pref"]);
        if (pref == 1) {
          session["prefs"][left]++;
        }
        if (pref == 2) {
          session["prefs"][right]++;
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
    session["left"] = left;
    session["right"] = right;
    var image1 = files[left];
    var image2 = files[right];
    showPage(response, image1, image2);
  }
  
  showResult(HttpResponse response, HttpSession session) {
    var maxval = 0;
    var maxitem = 0;
    for (var i = 0; i < session["prefs"].length; i++) {
      if (session["prefs"][i] > maxval) {
        maxval = session["prefs"][i];
        maxitem = i;
      }
    }
    var image = session["files"][maxitem];
    response.write("""
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
    response.close();
  }
  
  showPage(HttpResponse response, String image1, String image2) {
    response.write("""
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
    response.close();
  }
}

void main() {
  var server = new Server();
  var notFoundHandler = new NotFoundHandler();

  File here = new File(".");
  String herePath = here.absolute.path;
  print("here: $herePath");
  String newPath = "${herePath}/example/photocompare/files";
  if (herePath.endsWith("/photocompare/.")) {
    newPath = "${herePath}/files";
  }
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
