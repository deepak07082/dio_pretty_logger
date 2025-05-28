# 📱 dio_pretty_logger

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://pub.dev/packages/dio_pretty_logger)
[![pub](https://img.shields.io/pub/v/fast_cache_network_image)](https://pub.dev/packages/dio_pretty_logger)
[![dart](https://img.shields.io/badge/dart-pure%20dart-success)](https://pub.dev/packages/dio_pretty_logger)

A developer-friendly Dio interceptor that logs HTTP requests, responses, and errors in a clean and readable format. Useful for debugging API calls in Flutter/Dart projects.

## ✨ Features

- ✅ Logs HTTP **requests**, **responses**, and **errors**.
- ✅ Pretty print format with key metadata.
- ✅ Lightweight and easy to integrate.
- ✅ Fully customizable logging output.

## 📦 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  dio_pretty_logger: ^latest_version
```

```sh
dependencies:
  flutter pub get
```


## 🚀 Usage
```dart
import 'package:dio/dio.dart';
import 'package:dio_pretty_logger/dio_pretty_logger.dart';

final dio = Dio();

dio.interceptors.add(prettyInterceptorsWrapper);
```

if you want print raw Map or list use this functions

```dart
import 'package:dio_pretty_logger/dio_pretty_logger.dart';

var map = {
    "key":"value",
};
DioPrettyLogger.printPrettyMap(map);

// For list
var list = [map];
DioPrettyLogger.printPrettyList(list);
```

## 🔧 DioPrettyLogger Property Guide

| Property             | Type       | Default         | Description                                                       |
| -------------------- | ---------- | --------------- | ----------------------------------------------------------------- |
| `showRequest`        | `bool`     | `true`          | Whether to log request basic info (method and URL).               |
| `showRequestHeader`  | `bool`     | `true`          | Whether to log request headers.                                   |
| `showRequestBody`    | `bool`     | `true`          | Whether to log the body (query params or payload) of the request. |
| `showResponseBody`   | `bool`     | `true`          | Whether to log the response body.                                 |
| `showResponseHeader` | `bool`     | `false`         | Whether to log response headers.                                  |
| `showErrorMsg`       | `bool`     | `true`          | Whether to log error messages on failed requests.                 |
| `compact`            | `bool`     | `true`          | If `true`, will compact maps/lists when possible.                 |
| `maxWidth`           | `int`      | `90`            | Maximum character width before wrapping log lines.                |
| `chunkSize`          | `int`      | `20`            | Chunk size for breaking up `Uint8List` log output.                |
| `maxListPrintLength` | `int`      | `2`             | Max items to show in a large list. `0` to disable limit.          |
| `logPrint`           | `Function` | `debugPrint`    | Custom logging function. Only logs if `kDioLogenable` is `true`.  |
| `kDioLogenable`      | `bool`     | `!kReleaseMode` | Whether logging is enabled. Usually disabled in release builds.   |
| `tabStep`            | `String`   | `'    '`        | Number of spaces used per indentation level.                      |
| `kInitialTab`        | `int`      | `1`             | Initial tab depth for nested structures.                          |


## 📄 License
This project is licensed under the MIT License. See the [LICENSE](https://github.com/deepak07082/dio_pretty_logger/blob/main/LICENSE) file for details.

## 💬 Contributing
Feel free to submit issues or pull requests. Contributions are welcome!

## 🌐 Author
Made with ❤️ by Deepak.