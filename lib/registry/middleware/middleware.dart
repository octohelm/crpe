import 'package:contextdart/contextdart.dart';
import 'package:shelf/shelf.dart';

abstract class MiddlewareBuilder {
  static Middleware composeMiddlewares(List<MiddlewareBuilder> builders) {
    return (innerHandler) {
      Handler handler = innerHandler;

      for (var i = builders.length - 1; i >= 0; i--) {
        handler = builders[i].build(handler);
      }

      return (request) => handler(request);
    };
  }

  static injectContext(Context Function() inject) {
    return ContextInjector(inject);
  }

  Handler build(Handler next);
}

class ContextInjector implements MiddlewareBuilder {
  Context Function() inject;

  ContextInjector(this.inject);

  @override
  Handler build(Handler next) {
    return (request) {
      return inject().run(() => next(request));
    };
  }
}
