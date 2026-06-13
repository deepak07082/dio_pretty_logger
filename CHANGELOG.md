## 2.0.0

**Breaking change** — complete API redesign.

* `DioPrettyLogger` is now a proper `Interceptor` subclass. Add it directly:
  `dio.interceptors.add(DioPrettyLogger())`.
* All configuration is now passed via constructor parameters instead of static
  mutable fields, making it safe to use multiple loggers with different settings.
* Removed the global `prettyInterceptorsWrapper` variable.
* **Bug fix**: `onResponse` now forwards the full `Response` object to
  `handler.next` (previously it incorrectly passed only `response.data`,
  breaking downstream interceptors).
* **Bug fix**: error response body is now printed correctly in `onError`.
* **Bug fix**: `maxListPrintLength` is now respected (previously hardcoded to 2).
* **Bug fix**: removed the always-true `i >= 0` condition in `_printBlock`.
* Added JSON string auto-detection — string bodies that contain valid JSON are
  decoded and pretty-printed.
* Fixed typo: `kDioLogenable` → `enabled`.
* Renamed `showErrorMsg` → `showError`.
* Updated flutter constraint to `>=3.27.0` (Flutter 3.44-compatible).
* Added `dio: ^5.0.0` version constraint.
* Expanded test suite (request, response, error, truncation, disabled state).

## 1.0.4

* prettyMap design alter

## 1.0.3

* onRequest parameter added

## 1.0.2

* onRequest method parameter added

## 1.0.1

* Initial release.