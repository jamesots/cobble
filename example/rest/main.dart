import 'package:cobble/cobble.dart';
import 'dart:io';

class ThingHandler extends RestHandler {
  Map<String, String> things = {};

  @override
  bool checkAuthenticated(HttpRequest request) {
    return true;
  }

  var getRe = new RegExp(r"^/things/(.+)$");

  Map onGet(HttpRequest request) {
    if (getRe.hasMatch(request.uri.path)) {
      var match = getRe.firstMatch(request.uri.path);
      var id = match.group(1);
      return {
        "thing": things[id]
      };
    } else {
      return {
        "things": things
      };
    }
  }

  Map onPost(HttpRequest request, dynamic json) {
    if (things.containsKey(json["name"])) {
      conflict(request);
      return {
        "result": "Item already exists"
      };
    }
    things[json["name"]] = json["value"];
    request.response.headers.add("Location", "/things/${json["name"]}");
    return {
      "result": "Created"
    };
  }

//  onPut(HttpRequest request, dynamic json) {
//
//  }

  Map onDelete(HttpRequest request, dynamic json) {
    if (!things.containsKey(json["name"])) {

    }
    things.remove(json['name']);
    return {
      "result": "Deleted"
    };
  }
}

void main() {
  var server = new Server();

  File here = new File(".");
  String herePath = here.absolute.path;
  print("here: $herePath");

  String newPath = "${herePath}/example/rest/files";
  if (herePath.endsWith("/rest/.")) {
    newPath = "${herePath}/files";
  }
  var fileHandler = new FileHandler(newPath);

  server.listen('127.0.0.1', 8081);

  var thingHandler = new ThingHandler();

  server.mapRequestHandlers({
    r"^/things$": thingHandler.onRequest,
    r"^/things/.+$": thingHandler.onRequest
  });

  server.defaultRequestHandler = fileHandler.onRequest;
}
