import 'dart:io';

import 'package:logr/logr.dart';
import 'package:roundtripper/roundtripper.dart' show ResponseException;
import 'package:shelf/shelf.dart';

import 'middleware.dart';

class MiddlewareLog implements MiddlewareBuilder {
  @override
  Handler build(Handler next) {
    return (request) async {
      var requestStart = DateTime.now();
      var response = await next(request);

      var logger = Logger.current;

      if (response.statusCode >= HttpStatus.badRequest) {
        if (response.statusCode >= HttpStatus.internalServerError) {
          logger?.error(ResponseException(response.statusCode),
              _logEntities(request, response, requestStart));
        } else {
          logger?.info(_logEntities(request, response, requestStart));
        }
      } else {
        logger?.info(_logEntities(request, response, requestStart));
      }

      return response;
    };
  }

  Map _logEntities(Request request, Response response, DateTime requestStart) {
    var cost = DateTime.now().difference(requestStart);

    return {
      "method": request.method,
      "request": "/${request.url.toString()}",
      "status": response.statusCode,
      "cost": _formatDuration(cost),
    };
  }

  String _formatDuration(Duration d) {
    var microseconds = d.inMicroseconds;
    var hours = microseconds ~/ Duration.microsecondsPerHour;
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);
    var minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);
    var seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);
    var milliseconds = microseconds / Duration.millisecondsPerSecond;

    return [
      hours > 0 ? "${hours}h" : "",
      minutes > 0 ? "${minutes}m" : "",
      seconds > 0 ? "${seconds}s" : "",
      milliseconds > 0 ? "${milliseconds}ms" : "",
    ].join("");
  }
}
