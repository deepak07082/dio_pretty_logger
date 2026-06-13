import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A ready-made [InterceptorsWrapper] that logs requests, responses, and errors
/// using a default [DioPrettyLogger] instance.
///
/// Usage:
/// ```dart
/// dio.interceptors.add(prettyInterceptorsWrapper);
/// ```
///
/// For custom configuration, build your own wrapper with a configured logger:
/// ```dart
/// final logger = DioPrettyLogger(showResponseHeader: true, maxWidth: 120);
/// dio.interceptors.add(InterceptorsWrapper(
///   onRequest: (options, handler) {
///     final base = BaseOptions(baseUrl: options.baseUrl, ...);
///     logger.onRequest(base, options.path);
///     handler.next(options);
///   },
///   onResponse: (response, handler) {
///     logger.onResponse(response, handler, response.data);
///     handler.next(response);
///   },
///   onError: (err, handler) {
///     logger.onError(err, handler);
///     handler.next(err);
///   },
/// ));
/// ```
InterceptorsWrapper prettyInterceptorsWrapper = InterceptorsWrapper(
  onRequest: (options, handler) {
    final baseOption = BaseOptions(
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
    DioPrettyLogger().onRequest(baseOption, options.path);
    handler.next(options);
  },
  onError: (e, handler) {
    DioPrettyLogger().onError(e, handler);
    handler.next(e);
  },
  onResponse: (e, handler) {
    DioPrettyLogger().onResponse(e, handler, e.data);
    handler.next(e); // passes the full Response, not just e.data
  },
);

/// A pretty-printing logger for Dio HTTP requests, responses, and errors.
///
/// Instantiate and call [onRequest], [onResponse], and [onError] directly,
/// or use the provided [prettyInterceptorsWrapper] to plug it into Dio:
///
/// ```dart
/// dio.interceptors.add(prettyInterceptorsWrapper);
/// ```
///
/// For per-call logging outside Dio:
/// ```dart
/// final logger = DioPrettyLogger();
/// logger.onRequest(myBaseOptions, '/endpoint', data: myPayload);
/// ```
class DioPrettyLogger {
  /// Log the outgoing request line (method + URL). Defaults to `true`.
  final bool showRequest;

  /// Log request headers, query parameters, and extras. Defaults to `true`.
  final bool showRequestHeader;

  /// Log the request body / form data. Defaults to `true`.
  final bool showRequestBody;

  /// Log the response body. Defaults to `true`.
  final bool showResponseBody;

  /// Log response headers. Defaults to `false`.
  final bool showResponseHeader;

  /// Log [DioException] errors. Defaults to `true`.
  final bool showError;

  /// Collapse small maps and lists onto a single line. Defaults to `false`.
  final bool compact;

  /// Maximum line width before wrapping text. Defaults to `90`.
  final int maxWidth;

  /// Number of bytes per row when printing [Uint8List] bodies. Defaults to `20`.
  final int chunkSize;

  /// Maximum list items to print. Set to `0` for unlimited. Defaults to `10`.
  final int maxListPrintLength;

  /// Master switch. When `false` nothing is logged.
  /// Defaults to `!kReleaseMode` (enabled in debug/profile, silent in release).
  final bool enabled;

  /// Custom sink for log output. Defaults to [debugPrint].
  final void Function(Object object) logPrint;

  static const int _kInitialTab = 1;
  static const String _tabStep = '    ';

  DioPrettyLogger({
    this.showRequest = true,
    this.showRequestHeader = true,
    this.showRequestBody = true,
    this.showResponseBody = true,
    this.showResponseHeader = false,
    this.showError = true,
    this.compact = false,
    this.maxWidth = 90,
    this.chunkSize = 20,
    this.maxListPrintLength = 10,
    bool? enabled,
    void Function(Object object)? logPrint,
  }) : enabled = enabled ?? !kReleaseMode,
       logPrint = logPrint ?? ((obj) => debugPrint(obj.toString()));

  // ─── Logging methods ──────────────────────────────────────────────────────
  // These are pure logging methods — they do NOT call handler.next().
  // The caller (e.g. prettyInterceptorsWrapper) is responsible for forwarding.

  /// Logs an outgoing request.
  ///
  /// [options] provides the base URL and common headers.
  /// [endPoint] is the specific path for this request.
  /// [reqMethod] overrides the HTTP method from [options] when supplied.
  /// [data] overrides the body/query params from [options] when supplied.
  void onRequest(
    BaseOptions options,
    String endPoint, {
    String? reqMethod,
    Map<String, dynamic>? data,
  }) {
    if (!enabled) return;

    final method = reqMethod ?? options.method.toUpperCase();
    final body = data ?? options.queryParameters;

    if (showRequest) {
      _printBoxed(
        header: 'Request ║ $method ',
        text: options.baseUrl + endPoint,
      );
    }

    if (showRequestHeader) {
      _printMapAsTable(options.queryParameters, header: 'Query Parameters');
      final headers = Map<String, dynamic>.from(options.headers);
      headers['contentType'] = options.contentType?.toString();
      headers['responseType'] = options.responseType.toString();
      headers['followRedirects'] = options.followRedirects;
      headers['connectTimeout'] = options.connectTimeout?.toString();
      headers['receiveTimeout'] = options.receiveTimeout?.toString();
      _printMapAsTable(headers, header: 'Headers');
      _printMapAsTable(options.extra, header: 'Extras');
    }

    if (showRequestBody) {
      _printMapAsTable(body, header: 'Body');
    }
  }

  /// Logs an incoming response.
  ///
  /// [data] is the decoded response body (often already parsed by Dio).
  /// The [handler] parameter is accepted for API compatibility but is not used
  /// here — call [handler.next] in your [InterceptorsWrapper] callback.
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
    dynamic data,
  ) {
    if (!enabled) return;

    _printBoxed(
      header:
          'Response ║ ${response.requestOptions.method} ║ Status: ${response.statusCode} ${response.statusMessage}',
      text: response.requestOptions.uri.toString(),
    );

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
      _printData(data);
      logPrint('║');
      _printLine('╚');
    }
  }

  /// Logs a [DioException] error.
  ///
  /// The [handler] parameter is accepted for API compatibility but is not used
  /// here — call [handler.next] in your [InterceptorsWrapper] callback.
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled || !showError) return;

    if (err.type == DioExceptionType.badResponse) {
      final uri = err.response?.requestOptions.uri;
      _printBoxed(
        header:
            'DioError ║ Status: ${err.response?.statusCode} ${err.response?.statusMessage}',
        text: uri.toString(),
      );
      if (err.response?.data != null) {
        logPrint('╔ ${err.type}');
        _printData(err.response!.data);
      }
      _printLine('╚');
      logPrint('');
    } else {
      _printBoxed(header: 'DioError ║ ${err.type}', text: err.message);
    }
  }

  // ─── Public helpers ───────────────────────────────────────────────────────

  /// Pretty-prints [data] as a boxed map with an optional [customTitle].
  void printPrettyMap(
    Map<dynamic, dynamic> data, {
    String customTitle = '',
    int initialTab = _kInitialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    logPrint('');
    logPrint('╔╣ $customTitle');
    logPrint('║');
    _printPrettyMapData(
      data,
      initialTab: initialTab,
      isListItem: isListItem,
      isLast: isLast,
    );
    _printLine('╚');
    logPrint('');
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _printBoxed({String? header, String? text}) {
    logPrint('');
    logPrint('╔╣ $header');
    logPrint('║  $text');
    _printLine('╚');
  }

  /// Dispatches [data] to the appropriate pretty-printer.
  void _printData(dynamic data) {
    if (data == null) return;

    if (data is Map) {
      _printPrettyMapData(data);
    } else if (data is Uint8List) {
      logPrint('║${_indent()}[');
      _printUint8List(data);
      logPrint('║${_indent()}]');
    } else if (data is List) {
      logPrint('║${_indent()}[');
      _printPrettyList(data);
      logPrint('║${_indent()}]');
    } else if (data is String) {
      // Attempt to decode and re-format JSON strings.
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          _printPrettyMapData(decoded);
        } else if (decoded is List) {
          logPrint('║${_indent()}[');
          _printPrettyList(decoded);
          logPrint('║${_indent()}]');
        } else {
          _printBlock(data);
        }
      } catch (_) {
        _printBlock(data);
      }
    } else {
      _printBlock(data.toString());
    }
  }

  void _printLine([String pre = '', String suf = '╝']) =>
      logPrint('$pre${'═' * maxWidth}$suf');

  void _printBlock(String msg) {
    final lines = (msg.length / maxWidth).ceil();
    for (var i = 0; i < lines; ++i) {
      logPrint(
        '║ ${msg.substring(i * maxWidth, math.min<int>(i * maxWidth + maxWidth, msg.length))}',
      );
    }
  }

  String _indent([int tabCount = _kInitialTab]) => _tabStep * tabCount;

  void _printPrettyMapData(
    Map<dynamic, dynamic> data, {
    int initialTab = _kInitialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    var tabs = initialTab;
    final isRoot = tabs == _kInitialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) logPrint('║$initialIndent{');

    final entries = data.entries.toList();
    for (var index = 0; index < entries.length; index++) {
      final key = entries[index].key;
      final isLastEntry = index == entries.length - 1;
      dynamic value = entries[index].value;

      if (value is String) {
        value = '"${value.replaceAll(RegExp(r'([\r\n])+'), ' ')}"';
      }

      if (value is Map) {
        if (compact && _canFlattenMap(value)) {
          logPrint(
            '║${_indent(tabs)} "$key": $value${!isLastEntry ? ',' : ''}',
          );
        } else {
          logPrint('║${_indent(tabs)} "$key": {');
          _printPrettyMapData(value, initialTab: tabs);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          logPrint('║${_indent(tabs)} "$key": $value');
        } else {
          logPrint('║${_indent(tabs)} "$key": [');
          _printPrettyList(value, tabs: tabs);
          logPrint('║${_indent(tabs)} ]${isLastEntry ? '' : ','}');
        }
      } else {
        final msg = value.toString().replaceAll('\n', '');
        final indent = _indent(tabs);
        final lineWidth = maxWidth - indent.length;
        if (msg.length + indent.length > lineWidth) {
          final lineCount = (msg.length / lineWidth).ceil();
          for (var i = 0; i < lineCount; ++i) {
            logPrint(
              '║${_indent(tabs)}${i == 0 ? '" $key: "' : ''}${msg.substring(i * lineWidth, math.min<int>(i * lineWidth + lineWidth, msg.length))}',
            );
          }
        } else {
          logPrint('║${_indent(tabs)} "$key": $msg${!isLastEntry ? ',' : ''}');
        }
      }
    }

    logPrint('║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  void _printPrettyList(List<dynamic> list, {int tabs = _kInitialTab}) {
    final printLength =
        (maxListPrintLength > 0 && list.length > maxListPrintLength)
        ? maxListPrintLength
        : list.length;

    for (var i = 0; i < printLength; i++) {
      final e = list[i];
      final isLast = i == list.length - 1;
      if (e is Map) {
        if (compact && _canFlattenMap(e)) {
          logPrint('║${_indent(tabs)}  $e${!isLast ? ',' : ''}');
        } else {
          _printPrettyMapData(
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

    if (printLength < list.length) {
      logPrint(
        '║${_indent(tabs + 1)} ... and ${list.length - printLength} more items',
      );
    }
  }

  void _printUint8List(Uint8List list, {int tabs = _kInitialTab}) {
    for (var i = 0; i < list.length; i += chunkSize) {
      final chunk = list.sublist(i, math.min(i + chunkSize, list.length));
      logPrint('║${_indent(tabs)} ${chunk.join(', ')}');
    }
  }

  bool _canFlattenMap(Map<dynamic, dynamic> map) =>
      map.values.every((v) => v is! Map && v is! List) &&
      map.toString().length < maxWidth;

  bool _canFlattenList(List<dynamic> list) =>
      list.length < 10 && list.toString().length < maxWidth;

  void _printMapAsTable(Map<dynamic, dynamic>? map, {String? header}) {
    if (map == null || map.isEmpty) return;
    logPrint('╔ $header ');
    _printData(map);
    _printLine('╚');
  }
}
