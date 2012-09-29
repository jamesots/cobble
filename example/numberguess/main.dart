#import('package:dartwebserver/webserver.dart');
#import('dart:io');
#import('dart:math', prefix:'Math');

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
  
  TheHandler() {
    rnd = new Math.Random(new Date.now().millisecondsSinceEpoch);
  }
  
  onRequest(HttpRequestWrapper request, HttpResponseWrapper response) {
    print("request received");
    response.statusCode = HttpStatus.OK;

    int number;
    int guess;
    int count;
    bool noGuess = true;
    Session session = request.session;
    if (request.session == null) {
      session = response.createSession();
      print("creating session");
    }
    Map<String, int> values = session.values;
    print("got session");
    if (values["number"] == null) {
      values["number"] = rnd.nextInt(100);
      values["count"] = 0;
    }
    number = values["number"];
    print("number = $number");
    if (request.queryParameters["guess"] != null) {
      try {
        guess = Math.parseInt(request.queryParameters["guess"]);
        values["count"]++;
        noGuess = false;
      } on FormatException catch (e) {
        noGuess = true;
      }
    }
    count = values["count"];

    response.outputStream.writeString("""
<html>
<head>
<title>Number Guessing Game</title>
</head>
<body>
<h1>Number Guessing Game</h1>
<img src="question.png"/>""");
    if (!noGuess) {
      if (guess > number) {
        response.outputStream.writeString("<p>${guess} was too high! Try again.</p>");
      } else if (guess < number) {
        response.outputStream.writeString("<p>${guess} was too low! Try again.</p>");
      } else {
        response.outputStream.writeString("<p>Correct! Got it in ${count}. Let's do that again.</p>");
        values["number"] = rnd.nextInt(100);
        count = values["count"] = 0;
      }
    } else {
      response.outputStream.writeString("<p>I've thought of a number. What do you think it is?</p>");
    }
    response.outputStream.writeString("""
<form action="/">
Guess ${count + 1}
<input name="guess" />
</form>
</body>
</html>
""");
    response.outputStream.close();
  }
}

void main() {
  var server = new Server();
  var handler = new TheHandler();
  var notFoundHandler = new NotFoundHandler();

  File here = new File(".");
  String herePath = here.fullPathSync();
  print("here: $herePath");
  String newPath = "${herePath}/example/numberguess/files";
  var fileHandler = new FileHandler(newPath);
  fileHandler.notFoundHandler = notFoundHandler;
  
  server.listen('127.0.0.1', 8080);
  server.defaultRequestHandler = notFoundHandler;
  
  server.mapRequestHandlers({
    @"^/$": handler,
    @"^/one$": handler,
    @"\.(png|txt|gif|html|jpg)$": fileHandler
  });
}
