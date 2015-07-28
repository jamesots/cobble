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
        r'.*\.html$': htmlRequestHandler,
        r'/css/.*': cssRequestHandler
    });

Finally, it also supports REST requests. Anything added as a REST handler will only be
called either when the method is DELETE, or the method isn't DELETE and the
accepted content type is application/json:

    server.mapRestHandlers({
        r'/farm/cow': cowRestHandler,
        r'/farm/horse': horseRestHandler
    });

The rest handlers need to be a subclass of RestHandler (though you can also use a RestHandler
anywhere else a RequestHandler is needed):

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
        r'/farm/cow': new CowRestHandler().onRequest
    }

There's also a FileHandler class to server files. This FileHandler will server files
from the /var/stuff/res directory, after first stripping off the initial '/resources/' part
of the path. So a URL of /resources/bob/thing.png would server up /var/stuff/res/bob/thing.png.
The path is validated so that the user can't get at files outside of the specified directory.
Appropriate mime types and error codes should be served.

    server.mapRequestHandlers({
        r'/resources/.*': new FileHandler('/var/stuff/res', '/resources/')
    }

If it is being used in Google App Engine, you can do this:

    runAppEngine(server.handleRequest);
