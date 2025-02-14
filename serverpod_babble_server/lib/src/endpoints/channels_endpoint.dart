import 'package:serverpod/serverpod.dart';
import 'package:serverpod_babble_server/src/generated/protocol.dart';

class ChannelsEndpoint extends Endpoint {
  Future<List<Channel>> getChannels(Session session) async {
    var channels = await Channel.db.find(
      session,
      // where: (channel) => channel.name.equals('General'),
    );
    return channels;
  }
}
