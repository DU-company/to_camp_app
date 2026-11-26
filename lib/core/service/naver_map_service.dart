import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

String? get _clientId => dotenv.env['NAVER_MAP_CLIENT_ID']?.trim();
bool get hasNaverMapClientId => _clientId?.isNotEmpty ?? false;

Future<void> initializeNaverMap() async {
  final clientId = _clientId;
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) &&
      clientId != null &&
      clientId.isNotEmpty) {
    await FlutterNaverMap().init(
      clientId: clientId,
      onAuthFailed: (error) =>
          debugPrint('네이버 지도 인증 실패 (${error.runtimeType})'),
    );
  }
}
