import 'package:flutter/material.dart';
import 'package:serverpod_babble_client/serverpod_babble_client.dart';
import 'package:serverpod_babble_flutter/main.dart';
import 'package:serverpod_babble_flutter/src/chat_page.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(channel?.name ?? 'Serverpod Example'),
        actions: [
          IconButton(
            onPressed: () {
              client.theme.changeTheme();
            },
            icon: Icon(Icons.color_lens),
          )
        ],
      ),
      drawer: _ChannelDrawer(
        channels: widget.channels,
        selectedChannel: _selectedChannel,
        onSelectedChannel: (channel) {
          setState(() {
            _selectedChannel = channel;
          });
        },
      ),
      body: controller != null
          ? ChatPage(
              key: ValueKey(controller.channel),
              controller: controller,
            )
          : const Center(
              child: Text('Select a channel'),
            ),
    );
  }
}

class _ChannelDrawer extends StatelessWidget {
  const _ChannelDrawer({
    required this.channels,
    required this.selectedChannel,
    required this.onSelectedChannel,
  });

  final List<Channel> channels;
  final String selectedChannel;
  final ValueChanged<String> onSelectedChannel;

  @override
  Widget build(BuildContext context) {
    var mt = MediaQuery.of(context);

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: mt.padding.top,
          ),
          ListTile(
            title: Text('You are signed in'),
            trailing: OutlinedButton(
              onPressed: () {},
              child: Text('Sign out'),
            ),
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Channels',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ListView(),
          ),
        ],
      ),
    );
  }
}
