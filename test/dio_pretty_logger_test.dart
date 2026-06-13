import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dio_pretty_logger/dio_pretty_logger.dart';

void main() {
  // Helper: create a logger that collects output into [logs].
  (DioPrettyLogger, List<String>) makeLogger({
    bool showRequest = true,
    bool showRequestHeader = true,
    bool showRequestBody = true,
    bool showResponseBody = true,
    bool showResponseHeader = false,
    bool showError = true,
    bool compact = true,
    int maxListPrintLength = 10,
  }) {
    final logs = <String>[];
    final logger = DioPrettyLogger(
      enabled: true,
      showRequest: showRequest,
      showRequestHeader: showRequestHeader,
      showRequestBody: showRequestBody,
      showResponseBody: showResponseBody,
      showResponseHeader: showResponseHeader,
      showError: showError,
      compact: compact,
      maxListPrintLength: maxListPrintLength,
      logPrint: (obj) => logs.add(obj.toString()),
    );
    return (logger, logs);
  }

  BaseOptions makeBaseOptions({
    String method = 'GET',
    String baseUrl = 'https://api.example.com',
    Map<String, dynamic>? queryParameters,
  }) {
    return BaseOptions(
      method: method,
      baseUrl: baseUrl,
      queryParameters: queryParameters ?? {},
    );
  }

  RequestOptions makeRequestOptions({
    String method = 'GET',
    String path = '/test',
    String baseUrl = 'https://api.example.com',
    Map<String, dynamic>? queryParameters,
    dynamic data,
  }) {
    return RequestOptions(
      method: method,
      path: path,
      baseUrl: baseUrl,
      queryParameters: queryParameters ?? {},
      data: data,
    );
  }

  group('DioPrettyLogger', () {
    group('constructor', () {
      test('enabled defaults to true in test (debug) mode', () {
        expect(DioPrettyLogger().enabled, isTrue);
      });

      test('enabled can be overridden to false', () {
        expect(DioPrettyLogger(enabled: false).enabled, isFalse);
      });

      test('custom logPrint is called', () {
        final captured = <String>[];
        final logger = DioPrettyLogger(
          enabled: true,
          logPrint: (obj) => captured.add(obj.toString()),
        );
        logger.onRequest(makeBaseOptions(), '/test');
        expect(captured, isNotEmpty);
      });
    });

    group('onRequest', () {
      test('logs request URL and method', () {
        final (logger, logs) = makeLogger();
        logger.onRequest(makeBaseOptions(method: 'POST'), '/users');
        final all = logs.join('\n');
        expect(all, contains('POST'));
        expect(all, contains('/users'));
      });

      test('does not log when enabled = false', () {
        final logs = <String>[];
        DioPrettyLogger(
          enabled: false,
          logPrint: (obj) => logs.add(obj.toString()),
        ).onRequest(makeBaseOptions(), '/test');
        expect(logs, isEmpty);
      });

      test('logs Map body', () {
        final (logger, logs) = makeLogger();
        logger.onRequest(
          makeBaseOptions(method: 'POST'),
          '/users',
          data: {'name': 'Alice', 'age': 30},
        );
        final all = logs.join('\n');
        expect(all, contains('name'));
        expect(all, contains('Alice'));
      });

      test('reqMethod overrides options.method', () {
        final (logger, logs) = makeLogger();
        logger.onRequest(
          makeBaseOptions(method: 'GET'),
          '/endpoint',
          reqMethod: 'PATCH',
        );
        expect(logs.join('\n'), contains('PATCH'));
      });

      test('skips request line when showRequest = false', () {
        final (logger, logs) = makeLogger(showRequest: false);
        logger.onRequest(makeBaseOptions(), '/test');
        expect(logs.any((l) => l.contains('Request')), isFalse);
      });

      test('logs query parameters when showRequestHeader = true', () {
        final (logger, logs) = makeLogger(showRequest: false, showRequestBody: false);
        logger.onRequest(
          makeBaseOptions(queryParameters: {'page': '1', 'limit': '20'}),
          '/items',
        );
        final all = logs.join('\n');
        expect(all, contains('page'));
        expect(all, contains('limit'));
      });
    });

    group('onResponse', () {
      Response<T> makeResponse<T>({
        required T data,
        int statusCode = 200,
        String statusMessage = 'OK',
        String method = 'GET',
        String path = '/test',
      }) {
        final opts = makeRequestOptions(method: method, path: path);
        return Response<T>(
          requestOptions: opts,
          data: data,
          statusCode: statusCode,
          statusMessage: statusMessage,
        );
      }

      test('logs status code and URL', () {
        final (logger, logs) = makeLogger();
        final handler = ResponseInterceptorHandler();
        logger.onResponse(makeResponse(data: {'ok': true}), handler, {'ok': true});
        final all = logs.join('\n');
        expect(all, contains('200'));
        expect(all, contains('/test'));
      });

      test('logs Map response body', () {
        final (logger, logs) = makeLogger();
        final data = {'id': 1, 'name': 'Bob'};
        logger.onResponse(
          makeResponse(data: data),
          ResponseInterceptorHandler(),
          data,
        );
        final all = logs.join('\n');
        expect(all, contains('id'));
        expect(all, contains('Bob'));
      });

      test('logs List response body', () {
        final (logger, logs) = makeLogger();
        final data = [1, 2, 3];
        logger.onResponse(makeResponse(data: data), ResponseInterceptorHandler(), data);
        final all = logs.join('\n');
        expect(all, contains('1'));
        expect(all, contains('2'));
      });

      test('logs Uint8List as bytes', () {
        final (logger, logs) = makeLogger();
        final data = Uint8List.fromList([0, 127, 255]);
        logger.onResponse(makeResponse(data: data), ResponseInterceptorHandler(), data);
        expect(logs.any((l) => l.contains('127')), isTrue);
      });

      test('decodes JSON string body', () {
        final (logger, logs) = makeLogger();
        const data = '{"key":"value"}';
        logger.onResponse(makeResponse(data: data), ResponseInterceptorHandler(), data);
        final all = logs.join('\n');
        expect(all, contains('key'));
        expect(all, contains('value'));
      });

      test('skips body when showResponseBody = false', () {
        final (logger, logs) = makeLogger(showResponseBody: false);
        final data = {'secret': 'hidden'};
        logger.onResponse(makeResponse(data: data), ResponseInterceptorHandler(), data);
        expect(logs.any((l) => l.contains('secret')), isFalse);
      });

      test('logs response headers when showResponseHeader = true', () {
        final (logger, logs) = makeLogger(showResponseHeader: true);
        final opts = makeRequestOptions();
        final response = Response(
          requestOptions: opts,
          data: {},
          statusCode: 200,
          statusMessage: 'OK',
          headers: Headers.fromMap({'content-type': ['application/json']}),
        );
        logger.onResponse(response, ResponseInterceptorHandler(), {});
        expect(logs.join('\n'), contains('content-type'));
      });

      test('does not log when enabled = false', () {
        final logs = <String>[];
        DioPrettyLogger(enabled: false, logPrint: (obj) => logs.add(obj.toString()))
            .onResponse(
              makeResponse(data: {}),
              ResponseInterceptorHandler(),
              {},
            );
        expect(logs, isEmpty);
      });
    });

    group('onError', () {
      DioException makeError({
        DioExceptionType type = DioExceptionType.badResponse,
        int statusCode = 404,
        dynamic data,
      }) {
        final opts = makeRequestOptions();
        return DioException(
          requestOptions: opts,
          type: type,
          message: 'Not found',
          response: Response(
            requestOptions: opts,
            statusCode: statusCode,
            statusMessage: 'Not Found',
            data: data,
          ),
        );
      }

      test('logs bad response errors', () {
        final (logger, logs) = makeLogger();
        logger.onError(makeError(), ErrorInterceptorHandler());
        final all = logs.join('\n');
        expect(all, contains('DioError'));
        expect(all, contains('404'));
      });

      test('logs error response body when present', () {
        final (logger, logs) = makeLogger();
        logger.onError(
          makeError(data: {'error': 'not_found'}),
          ErrorInterceptorHandler(),
        );
        final all = logs.join('\n');
        expect(all, contains('error'));
        expect(all, contains('not_found'));
      });

      test('logs connection-level errors', () {
        final (logger, logs) = makeLogger();
        final err = DioException(
          requestOptions: makeRequestOptions(),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out',
        );
        logger.onError(err, ErrorInterceptorHandler());
        expect(logs.join('\n'), contains('connectionTimeout'));
      });

      test('does not log when showError = false', () {
        final (logger, logs) = makeLogger(showError: false);
        logger.onError(makeError(), ErrorInterceptorHandler());
        expect(logs, isEmpty);
      });

      test('does not log when enabled = false', () {
        final logs = <String>[];
        DioPrettyLogger(enabled: false, logPrint: (obj) => logs.add(obj.toString()))
            .onError(makeError(), ErrorInterceptorHandler());
        expect(logs, isEmpty);
      });
    });

    group('printPrettyMap', () {
      test('prints all keys and values', () {
        final (logger, logs) = makeLogger();
        logger.printPrettyMap({'foo': 'bar', 'baz': 42});
        final all = logs.join('\n');
        expect(all, contains('foo'));
        expect(all, contains('bar'));
        expect(all, contains('42'));
      });

      test('handles nested maps', () {
        final (logger, logs) = makeLogger(compact: false);
        logger.printPrettyMap({'outer': {'inner': 'value'}});
        final all = logs.join('\n');
        expect(all, contains('outer'));
        expect(all, contains('inner'));
        expect(all, contains('value'));
      });

      test('handles map with 10 entries', () {
        final (logger, logs) = makeLogger();
        logger.printPrettyMap({for (var i = 0; i < 10; i++) 'key$i': 'value$i'});
        final all = logs.join('\n');
        for (var i = 0; i < 10; i++) {
          expect(all, contains('key$i'));
        }
      });
    });

    group('list truncation', () {
      test('truncates long lists to maxListPrintLength', () {
        final (logger, logs) = makeLogger(maxListPrintLength: 3);
        final opts = makeRequestOptions();
        final data = List.generate(20, (i) => i);
        logger.onResponse(
          Response(requestOptions: opts, data: data, statusCode: 200, statusMessage: 'OK'),
          ResponseInterceptorHandler(),
          data,
        );
        expect(logs.join('\n'), contains('and 17 more items'));
      });

      test('prints all items when maxListPrintLength = 0', () {
        final (logger, logs) = makeLogger(maxListPrintLength: 0);
        final opts = makeRequestOptions();
        final data = List.generate(15, (i) => i);
        logger.onResponse(
          Response(requestOptions: opts, data: data, statusCode: 200, statusMessage: 'OK'),
          ResponseInterceptorHandler(),
          data,
        );
        expect(logs.any((l) => l.contains('more items')), isFalse);
      });
    });
  });
}
