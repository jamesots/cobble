Cobble
======

A cobbled together web server
----------------------------

This is a simple-ish web server I cobbled together a while ago for a
personal project. I'm publishing it in case anyone else finds it useful.

How to use it
-------------

To create a really simple server which gives the same response to all requests, this
is all that is needed:

    var server = new Server();
    server.defaultRequestHandler = (matcher, (request, response) {
        // do request handling here
    });
    server.listen(InternetAddress.ANY, 8080);

You can also add request handlers with matchers:

    server.addRequestHandler((request) => request.method == 'POST', (request, response) {
        // do request handling here
    });

Or you can map request handlers using regular expressions:

    server.mapRequestHandlers({
        '.*\\.html$': htmlRequestHandler,
        '/css/.*': cssRequestHandler
    });

Finally, it also supports REST requests. Anything added as a REST handler will only be
called either when the method is DELETE, or the method isn't DELETE and the
accepted content type is application/json:

    server.mapRestHandlers({
        '/farm/cow': cowRestHandler,
        '/farm/horse': horseRestHandler
    });

You can create a subclass of RestHandler to make handling REST request easier:

    class CowRestHandler extends RestHandler {
        onGet(HttpRequest request, HttpResponse response) {
            // do something useful
        }

        onPut(HttpRequest request, HttpResponse response) {
            // do something useful
        }

        // POST, DELETE will return NOT_ALLOWED error code (405)
    }

    server.mapRestHandlers({
        '/farm/cow': new CowRestHandler().onRequest
    }

There's also a FileHandler class to server files. This FileHandler will server files
from the /var/stuff/res directory, after first stripping off the initial '/resources/' part
of the path. So a URL of /resources/bob/thing.png would server up /var/stuff/res/bob/thing.png.
The path is validated so that the user can't get at files outside of the specified directory.
Appropriate mime types and error codes should be served.

    server.mapRequestHandlers({
        '/resources/.*': new FileHandler('/var/stuff/res', '/resources/')
    }