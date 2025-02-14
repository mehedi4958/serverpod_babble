import 'package:serverpod_auth_email_flutter/serverpod_auth_email_flutter.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
import 'package:serverpod_babble_client/serverpod_babble_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_babble_flutter/src/disconnected_page.dart';
import 'package:serverpod_babble_flutter/src/loading_page.dart';
import 'package:serverpod_babble_flutter/src/main_page.dart';
import 'package:serverpod_chat_flutter/serverpod_chat_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

late SessionManager sessionManager;
late Client client;

void main() async {
  // Need to call this as SessionManager is using  Flutter bindings before
  // runApp() is called.

  WidgetsFlutterBinding.ensureInitialized();

  // Sets up a singleton client object that can be used to talk to the server from
  // anywhere in our app. The client is generated from your server code.
  // The client is set up to connect to a Serverpod running on a local server on
  // the default port. You will need to modify this to connect to staging or
  // production servers.

  client = Client(
    'http://$localhost:8080/',
    authenticationKeyManager: FlutterAuthenticationKeyManager(),
  )..connectivityMonitor = FlutterConnectivityMonitor();

  // session manager keeps track of the signed-in state of the user.
  // You can query it to see if the user is currently signed in and
  // get information about the user

  sessionManager = SessionManager(caller: client.modules.auth);
  await sessionManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serverpod Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const _SignInPage(),
    );
  }
}

// The _SignInPage either displays a dialog for signing in or,
// if the user is signed-in displays the _ConnectionPage

class _SignInPage extends StatefulWidget {
  const _SignInPage();

  @override
  State<_SignInPage> createState() => __SignInPageState();
}

class __SignInPageState extends State<_SignInPage> {
  @override
  void initState() {
    super.initState();
    sessionManager.addListener(_changedSessionStatus);
  }

  @override
  void dispose() {
    client.removeStreamingConnectionStatusListener(_changedSessionStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (sessionManager.isSignedIn) {
      return _ConnectionPage();
    } else {
      return Scaffold(
        body: Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: Center(
            child: SignInWithEmailButton(caller: client.modules.auth),
          ),
        ),
      );
    }
  }

  // this method is called whenever the user signs in or signs out
  void _changedSessionStatus() {
    setState(() {});
  }
}

// The _ConnectionPage can display three states; a loading spinner, a page
// if loading fails, connection to the server is broken, or, the main chat page
class _ConnectionPage extends StatefulWidget {
  const _ConnectionPage();

  @override
  State<_ConnectionPage> createState() => __ConnectionPageState();
}

class __ConnectionPageState extends State<_ConnectionPage> {
  // List of channels retrieved from the server.
  List<Channel>? _channels;
  // to check if trying to connect to the server
  bool _connecting = false;
  // contains a list of ChatControllers
  Map<String, ChatController> _chatControllers = {};

  @override
  void initState() {
    super.initState();

    // starts listening to the changes in the websocket connection
    client.addStreamingConnectionStatusListener(_changedConnectionStatus);
    _connect();
  }

  @override
  void dispose() {
    // stops listening to the websocket connection
    client.removeStreamingConnectionStatusListener(_changedConnectionStatus);
    _disposeChatControllers();
    super.dispose();
  }

  // disposes all the ChatControllers and removes references to them
  void _disposeChatControllers() {
    for (var chatController in _chatControllers.values) {
      chatController.dispose();
    }
    _chatControllers.clear();
  }

  // starts connecting to the server. Connection is completed when
  // established connection to the websocket and to all chat channel

  Future<void> _connect() async {
    // Reset to initial state
    setState(() {
      _channels = null;
      _connecting = true;
      _disposeChatControllers();
    });

    try {
      // Load list of channels
      _channels = await client.channels.getChannels();

      // makes sure the websocket is connected
      await client.openStreamingConnection();

      // sets up ChatController for the channels in the list
      for (var channel in _channels!) {
        var controller = ChatController(
          channel: channel.channel,
          module: client.modules.chat,
          sessionManager: sessionManager,
        );

        _chatControllers[channel.channel] = controller;

        // listens to the changes in the connection status of the channel
        controller.addConnectionStatusListener(_chatConnectionStatusChanged);
      }

      ///
      client.theme.stream.listen((event) {
        var theme = event as BabbleTheme;
        print('Theme Dark: ${theme.dark}');
      });
    } catch (e) {
      // failed to connect
      setState(() {
        _channels = null;
        _connecting = false;
      });
      return;
    }
  }

  // called when state of the websocket is changed
  void _changedConnectionStatus() {
    setState(() {});
  }

  // called when connection to the chat channel is established
  void _chatConnectionStatusChanged() {
    // makes sure the list of channels is received
    if (_channels == null || _channels!.isEmpty) {
      setState(() {
        _channels = null;
        _connecting = false;
      });
      return;
    }

    var numJoinedChannels = 0;

    // counts the number of joined channels
    for (var chatController in _chatControllers.values) {
      if (chatController.joinedChannel) {
        numJoinedChannels += 1;
      } else if (chatController.joinFailed) {
        setState(() {
          _channels = null;
          _connecting = false;
        });
        return;
      }
    }

    // if all the channel loading is complete
    if (numJoinedChannels == _chatControllers.length) {
      setState(() {
        _connecting = false;
      });
    }
  }

  // attempt to reconnect to the server
  void _reconnect() {
    if (client.streamingConnectionStatus ==
        StreamingConnectionStatus.disconnected) {
      _connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connecting) {
      return const LoadingPage();
    } else if (_channels == null ||
        client.streamingConnectionStatus ==
            StreamingConnectionStatus.disconnected) {
      return DisconnectedPage(
        onReconnect: _reconnect,
      );
    } else {
      return MainPage(
        channels: _channels!,
        chatControllers: _chatControllers,
      );
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  // These fields hold the last result or error message that we've received from
  // the server or null if no result exists yet.
  String? _resultMessage;
  String? _errorMessage;

  final _textEditingController = TextEditingController();

  // Calls the `hello` method of the `example` endpoint. Will set either the
  // `_resultMessage` or `_errorMessage` field, depending on if the call
  // is successful.
  void _callHello() async {
    try {
      final result = await client.channels.getChannels();
      setState(() {
        _errorMessage = null;
        _resultMessage = result.toString();
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: _callHello,
                child: const Text('Send to Server'),
              ),
            ),
            _ResultDisplay(
              resultMessage: _resultMessage,
              errorMessage: _errorMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// _ResultDisplays shows the result of the call. Either the returned result from
// the `example.hello` endpoint method or an error message.
class _ResultDisplay extends StatelessWidget {
  final String? resultMessage;
  final String? errorMessage;

  const _ResultDisplay({
    this.resultMessage,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    Color backgroundColor;
    if (errorMessage != null) {
      backgroundColor = Colors.red[300]!;
      text = errorMessage!;
    } else if (resultMessage != null) {
      backgroundColor = Colors.green[300]!;
      text = resultMessage!;
    } else {
      backgroundColor = Colors.grey[300]!;
      text = 'No server response yet.';
    }

    return Container(
      height: 50,
      color: backgroundColor,
      child: Center(
        child: Text(text),
      ),
    );
  }
}
