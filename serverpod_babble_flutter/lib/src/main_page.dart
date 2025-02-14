import 'package:flutter/material.dart';
import 'package:serverpod_babble_client/serverpod_babble_client.dart';
import 'package:serverpod_chat_flutter/serverpod_chat_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    required this.channels,
    required this.chatControllers,
  });

  final List<Channel> channels;
  final Map<String, ChatController> chatControllers;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late String _selectedChannel;

  @override
  void initState() {
    super.initState();
    _selectedChannel = widget.channels[0].channel;
  }

  @override
  Widget build(BuildContext context) {
    // finds current channel controller and channel information
    var controller = widget.chatControllers[_selectedChannel];

    Channel? channel;
    for (var c in widget.channels) {
      if (c.channel == _selectedChannel) {
        channel = c;
        break;
      }
    }
    return Container();
  }
}
