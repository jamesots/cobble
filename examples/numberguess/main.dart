#import('../../lib/webserver.dart');
#import('DRandom.dart');
#import('dart:io');

class NotFoundHandler implements WrappedRequestHandler {
  onRequest(HttpRequestWrapper request, HttpResponseWrapper response) {
    response.outputStream.writeString("""
NOT FOUND
""");
    response.outputStream.close();
  }
}

class TheHandler implements WrappedRequestHandler {
  DRandom rnd;
  
  TheHandler() {
    rnd = new DRandom.withSeed(new Date.now().milliseconds);
  }
  
  onRequest(HttpRequestWrapper request, HttpResponseWrapper response) {
    print("request received");
    response.statusCode = HttpStatus.OK;

    int number;
    int guess;
    int count;
    Session session = request.session;
    if (request.session == null) {
      session = response.createSession();
      print("creating session");
    }
    Map values = session.values;
    print("got session");
    if (values["number"] == null) {
      values["number"] = rnd.NextFromMax(100);
      values["count"] = 0;
    }
    number = values["number"];
    print("number = $number");
    guess = null;
    if (request.queryParameters["guess"] != null) {
      try {
        guess = Math.parseInt(request.queryParameters["guess"]);
        values["count"]++;
      } catch (BadNumberFormatException e) {
        
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
    if (guess != null) {
      if (guess > number) {
        response.outputStream.writeString("<p>${guess} was too high! Try again.</p>");
      } else if (guess < number) {
        response.outputStream.writeString("<p>${guess} was too low! Try again.</p>");
      } else {
        response.outputStream.writeString("<p>Correct! Got it in ${count}. Let's do that again.</p>");
        values["number"] = rnd.NextFromMax(100);
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
  String newPath = "${herePath}/examples/numberguess/files";
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
