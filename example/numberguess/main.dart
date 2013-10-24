import 'package:dartwebserver/webserver.dart';
import 'dart:io';
import 'dart:math' as Math;

class NotFoundHandler implements RequestHandler {
  onRequest(HttpRequest request, HttpResponse response) {
    response.write("""
NOT FOUND
""");
    response.close();
  }
}

class TheHandler implements RequestHandler {
  Math.Random rnd;
  
  TheHandler() {
    rnd = new Math.Random(new DateTime.now().millisecondsSinceEpoch);
  }
  
  onRequest(HttpRequest request, HttpResponse response) {
    print("request received");
    response.statusCode = HttpStatus.OK;

    int number;
    int guess;
    int count;
    bool noGuess = true;
    HttpSession session = request.session;
    print("got session");
    if (session["number"] == null) {
      session["number"] = rnd.nextInt(100);
      session["count"] = 0;
    }
    number = session["number"];
    print("number = $number");
    if (request.uri.queryParameters["guess"] != null) {
      try {
        guess = int.parse(request.uri.queryParameters["guess"]);
        session["count"]++;
        noGuess = false;
      } on FormatException catch (e) {
        noGuess = true;
      }
    }
    count = session["count"];

    response.write("""
<html>
<head>
<title>Number Guessing Game</title>
</head>
<body>
<h1>Number Guessing Game</h1>
<img src="question.png"/>""");
    if (!noGuess) {
      if (guess > number) {
        response.write("<p>${guess} was too high! Try again.</p>");
      } else if (guess < number) {
        response.write("<p>${guess} was too low! Try again.</p>");
      } else {
        response.write("<p>Correct! Got it in ${count}. Let's do that again.</p>");
        session["number"] = rnd.nextInt(100);
        count = session["count"] = 0;
      }
    } else {
      response.write("<p>I've thought of a number. What do you think it is?</p>");
    }
    response.write("""
<form action="/">
Guess ${count + 1}
<input name="guess" />
</form>
</body>
</html>
""");
    response.close();
  }
}

void main() {
  var server = new Server();
  var handler = new TheHandler();
  var notFoundHandler = new NotFoundHandler();

  File here = new File(".");
  String herePath = here.absolute.path;
  print("here: $herePath");
  String newPath = "${herePath}/example/numberguess/files";
  if (herePath.endsWith("/numberguess/.")) {
    newPath = "${herePath}/files";
  }
  var fileHandler = new FileHandler(newPath);
  fileHandler.notFoundHandler = notFoundHandler;
  
  server.listen('127.0.0.1', 8081);
  server.defaultRequestHandler = notFoundHandler;
  
  server.mapRequestHandlers({
    r"^/$": handler,
    r"^/one$": handler,
    r"\.(png|txt|gif|html|jpg)$": fileHandler
  });
}
