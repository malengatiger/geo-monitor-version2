import 'package:geo_monitor/library/errors/error_handler.dart';

import '../../l10n/translation_handler.dart';
import '../api/prefs_og.dart';

class GeoException implements Exception {

  late String _message;
  late String _translationKey;
  late String _errorType;
  late String _url;

  GeoException({required String message, required String translationKey,
  required String errorType, required String url}) {
    _message = message;
    _translationKey = translationKey;
    _errorType = errorType;
    _url = url;
  }

  @override
  String toString() {
    return _message;
  }

  Future<String> getTranslatedMessage() async{
    final sett = await prefsOGx.getSettings();
    final translated = await translator.translate(_translationKey, sett.locale!);
    return translated;
  }
  String getErrorType() {
    return _errorType;
  }
  String getUrl() {
    return _url;
  }

  void saveError() async {
    errorHandler.handleError(exception: this);
  }

  static const
      timeoutException = 'TimeoutException',
      socketException = 'SocketException',
      httpException = 'HttpException',
      formatException = 'FormatException';
}

