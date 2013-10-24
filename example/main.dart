import 'package:sqljocky/sqljocky.dart';
import 'package:options_file/options_file.dart';
import 'package:dartwebserver/webserver.dart';
import 'dart:io';
import 'dart:async';

abstract class DbHandler implements RequestHandler {
  String _user;
  String _password;
  String _host;
  String _db;
  int _port;
  ConnectionPool _pool;
  
  DbHandler(String this._user, String this._password, String this._host, String this._db, int this._port);
  
  Future connect() {
    _pool = new ConnectionPool(user: _user, password: _password, host: _host, db: _db, port: _port);
  }
}

class SqlHandler extends DbHandler {
  SqlHandler(String user, String password, String host, String db, int port) :
    super(user, password, host, db, port);

  onRequest(HttpRequest request, HttpResponse response) {
    void writeIt(var fieldNames, var results) {
      response.write("""
<html>
<head>
<title>Test</title>
</head>
<body>
<h1>Test</h1>
<form action="/query">
<input name="sql" />
</form>
<p>${fieldNames}</p>
<p>${results}</p>
</body>
</html>""");
      response.close();
    };
    if (request.uri.queryParameters["sql"] != null) {
      connect().then((x) {
        print("connected");
        return _pool.query(request.uri.queryParameters["sql"]);
      }).then((Results results) {
        print("got results");
        _pool.close();
        List<String> fieldNames = new List<String>();
        for (Field field in results.fields) {
          fieldNames.add("${field.name}:${field.type}");
        }
        response.statusCode = HttpStatus.OK;
        writeIt(fieldNames, "");
      });
    } else {
      writeIt("", "");
    }
  }
}

class TheHandler extends DbHandler {
  TheHandler(String user, String password, String host, String db, int port) :
    super(user, password, host, db, port);
  
  onRequest(HttpRequest request, HttpResponse response) {
    print("request received");
    response.statusCode = HttpStatus.OK;

    String name = "";
    var session = request.session;
    if (session.isNew) {
      print("new session");
    } else {
      print("got session");
      if (request.uri.queryParameters["name"] != null) {
        print("got param");
        name = request.uri.queryParameters["name"];
        print("name is $name");
        session["name"] = name;
        print("stored name");
      } else {
        print("get naem from session");
        name = session["name"];
        print("name is $name");
      }
    }
    response.write("""
<html>
<head>
<title>Welcome</title>
</head>
<body>
<h1>Welcome $name</h1>
<form action="/">
<input name="name" />
</form>
</body>
</html>
""");
    response.close();
  }
}

void main() {
  OptionsFile options = new OptionsFile('connection.options');
  String user = options.getString('user');
  String password = options.getString('password');
  int port = options.getInt('port', 3306);
  String db = options.getString('db');
  String host = options.getString('host', 'localhost');
  print("$user $password $port $db $host");
  
  var server = new Server();
  var handler = new TheHandler(user, password, host, db, port);
  
  var queryHandler = new SqlHandler(user, password, host, db, port);
  
  File here = new File(".");
  String herePath = here.absolute.path;
  print("here: $herePath");
  String newPath = "${herePath}/example/files";
  if (herePath.endsWith("/example/.")) {
    newPath = "${herePath}/files";
  }

  var fileHandler = new FileHandler(newPath);
  server.listen('127.0.0.1', 8080);
  server.addRequestHandler((HttpRequest request) {
    return request.uri.path == "/query";
  }, queryHandler);
  server.addRequestHandler((HttpRequest request) {
    return request.uri.path.endsWith(".png") || request.uri.path.endsWith(".txt") || request.uri.path.endsWith(".ico"); 
  }, fileHandler);
  server.defaultRequestHandler = handler;
}
