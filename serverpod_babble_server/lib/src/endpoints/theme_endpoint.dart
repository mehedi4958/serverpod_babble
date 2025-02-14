import 'package:serverpod/serverpod.dart';
import 'package:serverpod_babble_server/src/generated/protocol.dart';

class ThemeEndpoint extends Endpoint {
  var dark = false;

  @override
  Future<void> streamOpened(StreamingSession session) async {
    sendStreamMessage(session, BabbleTheme(dark: dark));

    session.messages.addListener('themeChange', (message) {
      // var theme = message as BabbleTheme;
      sendStreamMessage(session, message);
    });
  }

  Future<void> changeTheme(Session session) async {
    dark = !dark;
    session.messages.postMessage('themeChange', BabbleTheme(dark: dark));
  }
}
