import 'package:flutter/material.dart';
import 'package:serverpod_chat_flutter/serverpod_chat_flutter.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
    required this.controller,
  });

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);

    return Column(
      children: [
        Expanded(
          child: ChatView(controller: controller),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          padding: EdgeInsets.only(bottom: mediaQueryData.padding.bottom),
          child: ChatInput(
            controller: controller,
            enableAttachments: false,
          ),
        ),
      ],
    );
  }
}
