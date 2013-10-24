import 'package:dartwebserver/webserver.dart';
import 'dart:io';
import 'dart:math' as Math;

class Board {
  List<String> _spaces;
  
  Board() {
    restart();
  }

  Board.clone(Board oldBoard) {
    _spaces = new List<String>(9);
    for (var i = 0; i < 9; i++) {
      _spaces[i] = oldBoard._spaces[i];
    }
  }
  
  void restart() {
    _spaces = new List<String>(9);
    for (var i = 0; i < 9; i++) {
      _spaces[i] = " ";
    }
  }
  
  void move(int pos, String person) {
    if (person != "X" && person != "O") {
      throw "Must be X or O";
    }
    if (pos < 0 || pos > 8) {
      throw "Must be between 0 and 8";
    }
    if (_spaces[pos] != " ") {
      throw "Move already taken";
    }
    _spaces[pos] = person;
  }
  
  void aiMove(String person) {
    
  }
  
  String whoWon() {
    if ((_spaces[0] != " "
        && _spaces[0] == _spaces[4] 
        && _spaces[4] == _spaces[8])
        || (_spaces[2] != " "
        && _spaces[2] == _spaces[4] 
        && _spaces[4] == _spaces[6])) {
      return _spaces[4];
    }
    for (var y = 0; y < 3; y++) {
      if (_spaces[y * 3] != " "
          && _spaces[y * 3] == _spaces[y * 3 + 1]
          && _spaces[y * 3 + 1] == _spaces[y * 3 + 2]) {
        return _spaces[y * 3];
      }
    }
    for (var x = 0; x < 3; x++) {
      if (_spaces[x] != " "
          && _spaces[x] == _spaces[x + 3]
          && _spaces[x + 3] == _spaces[x + 6]) {
        return _spaces[x];
      }
    }
    return " ";
  }
  
  String toString() {
    return """ ${_spaces[0]} | ${_spaces[1]} | ${_spaces[2]}  
---+---+---
 ${_spaces[3]} | ${_spaces[4]} | ${_spaces[5]} 
---+---+---
 ${_spaces[6]} | ${_spaces[7]} | ${_spaces[8]} """;
  }
}

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
  
  TheHandler() {
    rnd = new Math.Random(new DateTime.now().millisecondsSinceEpoch);
  }
  
  onRequest(HttpRequest request, HttpResponse response) {
    print("request received");
    response.statusCode = HttpStatus.OK;
    response.write("Hello");
    throw "oops";

    HttpSession session = request.session;
    if (session.isNew) {
      var board = new Board();
      session["board"] = new Board();
    }
    var board = session["board"];
    if (board.whoWon() != " ") {
      board.restart();
    }
    print("got session");
    var error = "";
    if (request.uri.queryParameters["move"] != null) {
      try {
        var move = int.parse(request.uri.queryParameters["move"]);
        board.move(move, "X");
        board.aiMove("O");
      } catch (e) {
        error = e.toString();
      }
    }
    
    var won = "";
    if (board.whoWon() != " ") {
      won = "${board.whoWon()} won";
    }

    response.write("""
<html>
<head>
<title>XandO</title>
</head>
<body>
<h1>XandO</h1>
<pre>
${session["board"].toString()}
</pre>
${error}
${won}
<form action="/">
Your Move:
<input name="move" />
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

  server.listen('127.0.0.1', 8081);
  server.defaultRequestHandler = notFoundHandler;
  
  server.mapRequestHandlers({
//    r"x": "hello",
    r"^/$": handler
  });
}
