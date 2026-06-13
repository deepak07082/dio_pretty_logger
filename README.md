# 📱 dio_pretty_logger

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://pub.dev/packages/dio_pretty_logger)
[![pub](https://img.shields.io/pub/v/dio_pretty_logger)](https://pub.dev/packages/dio_pretty_logger)
[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-blue)](https://flutter.dev)

A developer-friendly Dio interceptor that logs HTTP requests, responses, and errors in a clean, readable format. Useful for debugging API calls in Flutter/Dart projects.

## ✨ Features

- ✅ Proper `Interceptor` subclass — add directly to `dio.interceptors`.
- ✅ Instance-based configuration — run multiple loggers with different settings.
- ✅ Pretty-prints Maps, Lists, JSON strings, and binary (`Uint8List`) bodies.
- ✅ Silent in release builds by default (`enabled: !kReleaseMode`).
- ✅ Pluggable log sink via `logPrint` — redirect to any logger (e.g. `logger` package).
- ✅ Configurable list truncation, line width, and compaction.

## 📦 Installation

```yaml
dependencies:
  dio: ^5.9.2
  dio_pretty_logger: ^2.0.0
```

```sh
flutter pub get
```

## 🚀 Usage

### Basic

```dart
import 'package:dio/dio.dart';
import 'package:dio_pretty_logger/dio_pretty_logger.dart';

final dio = Dio();
dio.interceptors.add(DioPrettyLogger());
```

### Custom configuration

```dart
dio.interceptors.add(DioPrettyLogger(
  showResponseHeader: true,   // also log response headers
  showRequestBody: false,     // hide request bodies (e.g. to avoid logging passwords)
  maxWidth: 120,              // wider terminal
  maxListPrintLength: 5,      // show at most 5 list items
  enabled: !kReleaseMode,     // explicit control
));
```

### Custom log sink

```dart
import 'package:logger/logger.dart';

final _log = Logger();

dio.interceptors.add(DioPrettyLogger(
  logPrint: (obj) => _log.d(obj),
));
```

### Pretty-print a map directly

```dart
final logger = DioPrettyLogger(enabled: true);
logger.printPrettyMap({'key': 'value', 'nested': {'a': 1}});
```

## 🔧 Constructor Parameters

| Parameter            | Type                    | Default         | Description                                           |
| -------------------- | ----------------------- | --------------- | ----------------------------------------------------- |
| `showRequest`        | `bool`                  | `true`          | Log the request method and URL.                       |
| `showRequestHeader`  | `bool`                  | `true`          | Log request headers, query params, and extras.        |
| `showRequestBody`    | `bool`                  | `true`          | Log the request body or form data.                    |
| `showResponseBody`   | `bool`                  | `true`          | Log the response body.                                |
| `showResponseHeader` | `bool`                  | `false`         | Log response headers.                                 |
| `showError`          | `bool`                  | `true`          | Log `DioException` errors.                            |
| `compact`            | `bool`                  | `true`          | Collapse small maps/lists onto a single line.         |
| `maxWidth`           | `int`                   | `90`            | Maximum line width before wrapping.                   |
| `chunkSize`          | `int`                   | `20`            | Bytes per row when printing `Uint8List` responses.    |
| `maxListPrintLength` | `int`                   | `10`            | Maximum list items printed. `0` = unlimited.          |
| `enabled`            | `bool`                  | `!kReleaseMode` | Master switch — set to `false` to silence all output. |
| `logPrint`           | `void Function(Object)` | `debugPrint`    | Custom output sink.                                   |

## 🔀 Migration from v1.x

v2.0 is a **breaking change**. The old global `prettyInterceptorsWrapper` and static
`DioPrettyLogger.*` API have been replaced by a proper `Interceptor` subclass.

| v1.x                                                 | v2.x                                                      |
| ---------------------------------------------------- | --------------------------------------------------------- |
| `dio.interceptors.add(prettyInterceptorsWrapper)`    | `dio.interceptors.add(DioPrettyLogger())`                 |
| `DioPrettyLogger.showRequest = false` (static field) | `DioPrettyLogger(showRequest: false)` (constructor param) |
| `DioPrettyLogger.kDioLogenable = false`              | `DioPrettyLogger(enabled: false)`                         |
| `DioPrettyLogger.printPrettyMap(map)` (static)       | `DioPrettyLogger().printPrettyMap(map)` (instance)        |

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/deepak07082/dio_pretty_logger/blob/main/LICENSE) file for details.

## 💬 Contributing

Feel free to submit issues or pull requests. Contributions are welcome!

## 🌐 Author

Made with ❤️ by Deepak.
