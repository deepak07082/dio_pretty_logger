import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

InterceptorsWrapper prettyInterceptorsWrapper = InterceptorsWrapper(
  onRequest: (options, handler) {
    var baseOption = BaseOptions(
      baseUrl: options.baseUrl,
      contentType: options.contentType,
      headers: options.headers,
      method: options.method,
      queryParameters: options.queryParameters,
      responseType: options.responseType,
      followRedirects: options.followRedirects,
      connectTimeout: options.connectTimeout,
      receiveTimeout: options.receiveTimeout,
      extra: options.extra,
      sendTimeout: options.sendTimeout,
      maxRedirects: options.maxRedirects,
    );
    DioPrettyLogger.onRequest(baseOption, options.path);
    handler.next(options);
  },
  onError: (e, handler) {
    DioPrettyLogger.onError(e, handler);
    handler.next(e);
  },
  onResponse: (e, handler) {
    DioPrettyLogger.onResponse(e, handler, e.data);
    handler.next(e.data);
  },
);

class DioPrettyLogger {
  static bool showRequest = true;
  static bool showRequestHeader = true;
  static bool showRequestBody = true;
  static bool showResponseBody = true;
  static bool showResponseHeader = false;
  static bool showErrorMsg = true;
  static const int kInitialTab = 1;
  static const String tabStep = '    ';
  static bool compact = true;
  static int maxWidth = 90;
  static const int chunkSize = 20;
  static void Function(Object object) logPrint = (value) {
    if (kDioLogenable) {
      debugPrint(value.toString());
    }
  };
  static bool kDioLogenable = !kReleaseMode;
  static int maxListPrintLength = 2;

  static void onRequest(
    BaseOptions options,
    String endPoint, {
    String? reqMethod,
    Map<String, dynamic>? data,
  }) {
    var method = reqMethod ?? options.method.toUpperCase();
    var reqdata = data ?? options.queryParameters;
    if (!kDioLogenable) {
      return;
    }
    if (showRequest) {
      _printRequestHeader(options.baseUrl, endPoint, method);
    }
    if (showRequestHeader) {
      _printMapAsTable(options.queryParameters, header: 'Query Parameters');
      final requestHeaders = options.headers;
      requestHeaders['contentType'] = options.contentType?.toString();
      requestHeaders['responseType'] = options.responseType.toString();
      requestHeaders['followRedirects'] = options.followRedirects;
      requestHeaders['connectTimeout'] = options.connectTimeout?.toString();
      requestHeaders['receiveTimeout'] = options.receiveTimeout?.toString();
      _printMapAsTable(requestHeaders, header: 'Headers');
      _printMapAsTable(options.extra, header: 'Extras');
    }
    if (showRequestBody) {
      final dynamic data = reqdata;
      if (data != null) {
        if (data is Map) {
          _printMapAsTable(reqdata, header: 'Body');
        } else if (data is FormData) {
          final formDataMap = <String, dynamic>{}
            ..addEntries(data.fields)
            ..addEntries(data.files);
          _printMapAsTable(formDataMap, header: 'Form data | ${data.boundary}');
        } else {
          _printBlock(data.toString());
        }
      }
    }
  }

  static void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDioLogenable) {
      return;
    }
    if (showErrorMsg) {
      if (err.type == DioExceptionType.badResponse) {
        final uri = err.response?.requestOptions.uri;
        _printBoxed(
          header:
              'DioError ║ Status: ${err.response?.statusCode} ${err.response?.statusMessage}',
          text: uri.toString(),
        );
        if (err.response != null && err.response?.data != null) {
          logPrint('╔ ${err.type}');
          _printResponse(null);
        }
        _printLine('╚');
        logPrint('');
      } else {
        _printBoxed(header: 'DioError ║ ${err.type}', text: err.message);
      }
    }
  }

  static void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
    data,
  ) {
    if (!kDioLogenable) {
      return;
    }
    _printResponseHeader(response);
    if (showResponseHeader) {
      final responseHeaders = <String, String>{};
      response.headers.forEach(
        (k, list) => responseHeaders[k] = list.toString(),
      );
      _printMapAsTable(responseHeaders, header: 'Headers');
    }

    if (showResponseBody) {
      logPrint('╔ Body');
      logPrint('║');
      _printResponse(data);
      logPrint('║');
      _printLine('╚');
    }
  }

  static void _printBoxed({String? header, String? text}) {
    logPrint('');
    logPrint('╔╣ $header');
    logPrint('║  $text');
    _printLine('╚');
  }

  static void _printResponse(data) {
    if (data != null) {
      if (data is Map) {
        printPrettyMapData(data);
      } else if (data is Uint8List) {
        logPrint('║${_indent()}[');
        _printUint8List(data);
        logPrint('║${_indent()}]');
      } else if (data is List) {
        logPrint('║${_indent()}[');
        printPrettyList(data);
        logPrint('║${_indent()}]');
      } else {
        _printBlock(data.toString());
      }
    }
  }

  static void _printResponseHeader(Response response) {
    final uri = response.requestOptions.uri;
    final method = response.requestOptions.method;
    _printBoxed(
      header:
          'Response ║ $method ║ Status: ${response.statusCode} ${response.statusMessage}',
      text: uri.toString(),
    );
  }

  static void _printRequestHeader(
    String baseUrl,
    String endpoint,
    String method,
  ) {
    final uri = baseUrl + endpoint;
    _printBoxed(header: 'Request ║ $method ', text: uri);
  }

  static void _printLine([String pre = '', String suf = '╝']) =>
      logPrint('$pre${'═' * maxWidth}$suf');

  static void _printBlock(String msg) {
    final lines = (msg.length / maxWidth).ceil();
    for (var i = 0; i < lines; ++i) {
      logPrint(
        (i >= 0 ? '║ ' : '') +
            msg.substring(
              i * maxWidth,
              math.min<int>(i * maxWidth + maxWidth, msg.length),
            ),
      );
    }
  }

  static String _indent([int tabCount = kInitialTab]) => tabStep * tabCount;

  static void printPrettyMap(
    Map data, {
    String customTitle = '',
    int initialTab = kInitialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    logPrint('');
    logPrint('╔╣ $customTitle');
    logPrint('║');
    printPrettyMapData(
      data,
      initialTab: initialTab,
      isListItem: isListItem,
      isLast: isLast,
    );
    _printLine('╚');
    logPrint('');
  }

  static void printPrettyMapData(
    Map data, {
    int initialTab = kInitialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    var tabs = initialTab;
    final isRoot = tabs == kInitialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) logPrint('║$initialIndent{');

    data.keys.toList().asMap().forEach((index, dynamic key) {
      final isLast = index == data.length - 1;
      dynamic value = data[key];
      if (value is String) {
        value = '"${value.replaceAll(RegExp(r'([\r\n])+'), " ")}"';
      }
      if (value is Map) {
        if (compact && _canFlattenMap(value)) {
          logPrint('║${_indent(tabs)} "$key": $value${!isLast ? ',' : ''}');
        } else {
          logPrint('║${_indent(tabs)} "$key": {');
          printPrettyMapData(value, initialTab: tabs);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          logPrint('║${_indent(tabs)} "$key": $value');
        } else {
          logPrint('║${_indent(tabs)} "$key": [');
          printPrettyList(value, tabs: tabs);
          logPrint('║${_indent(tabs)} ]${isLast ? '' : ','}');
        }
      } else {
        final msg = value.toString().replaceAll('\n', '');
        final indent = _indent(tabs);
        final linWidth = maxWidth - indent.length;
        if (msg.length + indent.length > linWidth) {
          final lines = (msg.length / linWidth).ceil();
          for (var i = 0; i < lines; ++i) {
            logPrint(
              '║${_indent(tabs)}${i == 0 ? '" $key: "' : ''}${msg.substring(i * linWidth, math.min<int>(i * linWidth + linWidth, msg.length))}',
            );
          }
        } else {
          logPrint('║${_indent(tabs)} "$key": $msg${!isLast ? ',' : ''}');
        }
      }
    });

    logPrint('║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  static void printPrettyList(List list, {int tabs = kInitialTab}) {
    var length = list.length;

    if (list.isNotEmpty && list.length > 10 && maxListPrintLength != 0) {
      length = 2;
    }

    for (var i = 0; i < length; i++) {
      final e = list[i];
      final isLast = i == list.length - 1;
      if (e is Map) {
        if (compact && _canFlattenMap(e)) {
          logPrint('║${_indent(tabs)}  $e${!isLast ? ',' : ''}');
        } else {
          printPrettyMapData(
            e,
            initialTab: tabs + 1,
            isListItem: true,
            isLast: isLast,
          );
        }
      } else {
        logPrint('║${_indent(tabs + 2)} $e${isLast ? '' : ','}');
      }
    }
    if (length != list.length) {
      logPrint(
        '║${_indent(tabs + 1)} and ${list.length - length} more values...',
      );
    }
    list.asMap().forEach((i, dynamic e) {});
  }

  static void _printUint8List(Uint8List list, {int tabs = kInitialTab}) {
    final chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    for (final element in chunks) {
      logPrint('║${_indent(tabs)} ${element.join(", ")}');
    }
  }

  static bool _canFlattenMap(Map map) {
    return map.values
            .where((dynamic val) => val is Map || val is List)
            .isEmpty &&
        map.toString().length < maxWidth;
  }

  static bool _canFlattenList(List list) {
    return list.length < 10 && list.toString().length < maxWidth;
  }

  static void _printMapAsTable(Map? map, {String? header}) {
    if (map == null || map.isEmpty) return;
    logPrint('╔ $header ');
    _printResponse(map);
    // map.forEach(
    //     (dynamic key, dynamic value) => _printKV(key.toString(), value));
    _printLine('╚');
  }
}
