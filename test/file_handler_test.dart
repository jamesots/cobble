library file_handler_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:path/path.dart' as path;

import 'dart:io';
import 'dart:async';

import 'package:dartwebserver/webserver.dart';

class MockRequest extends Mock implements HttpRequest {
  Uri uri;
}

class MockHttpHeaders extends Mock implements HttpHeaders {
  Map values = new Map();

  void set(String name, Object value) {
    values[name] = value;
  }
}

class MockResponse extends Mock implements HttpResponse {
  int statusCode;

  HttpHeaders headers = new MockHttpHeaders();

  Future addStream(Stream<List<int>> stream) {
    return new Future.value();
  }

  Future close() {
    return new Future.value();
  }
}

main() {
  group("file handler", () {
    test("should not serve non-existent files", () {
      var handler = new FileHandler(new Directory("test").absolute.path);

      var request = new MockRequest();
      request.uri = new Uri.http("localhost", "/bob");
      var response = new MockResponse();

      handler.onRequest(request, response);

      expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
    });

    test("should not serve files outside the directory", () {
      var handler = new FileHandler(new Directory("test").absolute.path);

      var request = new MockRequest();
      request.uri = new Uri.http("localhost", "../pubspec.yaml");
      var response = new MockResponse();

      handler.onRequest(request, response);

      expect(response.statusCode, equals(HttpStatus.FORBIDDEN));
    });

    test("should serve files in directory", () {
      var handler = new FileHandler(new Directory("test").absolute.path);

      var request = new MockRequest();
      request.uri = new Uri.http("localhost", "test.txt");
      var response = new MockResponse();

      handler.onRequest(request, response);

      expect(response.statusCode, equals(HttpStatus.OK));
    });

    test("should trim path", () {
      var handler = new FileHandler(new Directory("test").absolute.path, trim: "/xyz/");

      var request = new MockRequest();
      request.uri = new Uri.http("localhost", "/xyz/test.txt");
      var response = new MockResponse();

      handler.onRequest(request, response);

      expect(response.statusCode, equals(HttpStatus.OK));
    });

    test("should throw error if path isn't absolute", () {
      expect(()=>new FileHandler("somepath"), throws);
    });

    test("should throw error if path doesn't exist", () {
      expect(()=>new FileHandler(new Directory("./wibble").absolute.path), throws);
    });

    test("should throw error if trim doesn't start with /", () {
      expect(()=>new FileHandler(new Directory(".").absolute.path, trim: 'hello/'), throws);
    });

    test("should throw error if trim doesn't end with /", () {
      expect(()=>new FileHandler(new Directory(".").absolute.path, trim: '/hello'), throws);
    });
  });
}