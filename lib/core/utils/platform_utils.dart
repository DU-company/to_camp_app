import 'dart:io';

abstract class PlatformUtils {
  static String getPlatformType() {
    return Platform.isIOS ? 'IOS' : 'ANDROID';
  }
}
