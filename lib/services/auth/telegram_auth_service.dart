import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/services/partners_repository.dart';
import 'package:sexpedition_application_1/services/telegram_webapp_service.dart';

class TelegramAuthException implements Exception {
  const TelegramAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TelegramAuthService {
  TelegramAuthService._();

  static final TelegramAuthService instance = TelegramAuthService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isTelegramContext => TelegramWebAppService.instance.isInTelegramWebApp;

  Future<UserCredential> signInWithTelegramWebApp() async {
    final initData = TelegramWebAppService.instance.initData;
    if (initData.trim().isEmpty) {
      throw const TelegramAuthException(
        'Telegram initData не найден. Откройте приложение внутри Telegram.',
      );
    }

    final callable = _functions.httpsCallable('telegramWebAppSignIn');
    final response = await callable.call<Map<String, dynamic>>({
      'initData': initData,
    });

    final customToken = response.data['customToken'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw const TelegramAuthException(
        'Сервер не вернул токен авторизации Telegram.',
      );
    }

    final credential = await _auth.signInWithCustomToken(customToken);
    await PartnersRepository().ensureMyProfile();
    return credential;
  }
}
