import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:web_socket_channel/web_socket_channel.dart';

// ignore: must_be_immutable
class HTTPTerminalWidget extends StatefulWidget {
  WebSocketChannel? channel;

  HTTPTerminalWidget({Key? key}) : super(key: key);

  @override
  _WebsocketConsoleWidgetState createState() => _WebsocketConsoleWidgetState();
}

class _WebsocketConsoleWidgetState extends State<HTTPTerminalWidget> {
  TextEditingController uri =
      TextEditingController(text: "wss://localhost:20443/");
  TextEditingController msg = TextEditingController();

  List<String> _items = ["GET", "POST", "WebSocket"];
  String _selectedItem = "WebSocket";

  @override
  Widget build(BuildContext context) {
    DropdownButton method = DropdownButton<String>(
      value: _selectedItem,
      onChanged: (String? newValue) {
        if (newValue != null) setState(() => _selectedItem = newValue);
      },
      selectedItemBuilder: (context) =>
          _items.map((String item) => Text(item)).toList(),
      items: _items.map((String item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: item == _selectedItem
                ? TextStyle(fontWeight: FontWeight.bold)
                : TextStyle(fontWeight: FontWeight.normal),
          ),
        );
      }).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("HTTP Terminal"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: [
              method,
              Expanded(
                  child: Form(
                child: TextFormField(
                  controller: uri,
                  decoration: InputDecoration(labelText: 'URI'),
                ),
              )),
              TextButton(
                child: (widget.channel == null)
                    ? Text("Connect")
                    : Text("Disconnect"),
                onPressed: () {
                  setState(() {
                    if (widget.channel == null) {
                      widget.channel =
                          WebSocketChannel.connect(Uri.parse(uri.text));
                    } else {
                      widget.channel?.sink.close();
                      widget.channel = null;
                    }
                  });
                },
              )
            ]),
            Form(
              child: TextFormField(
                controller: msg,
                decoration: InputDecoration(labelText: 'Send a message'),
              ),
            ),
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
