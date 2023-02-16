import 'package:flutter/foundation.dart';
import 'package:riotagitator/ui/Common.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:web_socket_channel/web_socket_channel.dart';

// ignore: must_be_immutable
class WebsocketTerminalWidget extends StatefulWidget {
  WebSocketChannel? channel;

  WebsocketTerminalWidget({Key? key}) : super(key: key);

  @override
  WebsocketTerminalWidgetState createState() => WebsocketTerminalWidgetState();
}

class WebsocketTerminalWidgetState extends State<WebsocketTerminalWidget> {
  TextEditingController uri = TextEditingController(text: "wss://");
  TextEditingController msg = TextEditingController();

  @override
  Widget build(BuildContext context) {
    TextButton connectButton = TextButton(
      child: (widget.channel == null) ? Text("Connect") : Text("Disconnect"),
      onPressed: () {
        try {
          setState(() {
            if (widget.channel == null) {
              widget.channel = WebSocketChannel.connect(Uri.parse(uri.text));
            } else {
              widget.channel?.sink.close();
              widget.channel = null;
            }
          });
        } catch (e) {
          showAlertDialog(context, Text("Exception: $e"));
        }
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("Websocket Terminal"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: [
              Expanded(
                  child: Form(
                      child: TextFormField(
                          controller: uri,
                          decoration: InputDecoration(labelText: 'URL')))),
              connectButton,
            ]),
            Form(
                child: TextFormField(
                    controller: msg,
                    decoration: InputDecoration(labelText: 'Send a message'),
                    onFieldSubmitted: (value) => _sendMessage())),
            StreamBuilder(
              stream: widget.channel?.stream,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(snapshot.hasData ? '${snapshot.data}' : ''),
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _sendMessage() {
    if (msg.text.isNotEmpty) {
      widget.channel?.sink.add(msg.text);
    }
  }

  @override
  void dispose() {
    widget.channel?.sink.close();
    super.dispose();
  }
}
