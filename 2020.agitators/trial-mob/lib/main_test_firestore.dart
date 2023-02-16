import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state_notifier/state_notifier.dart';

class FS_Count {
  FS_Count(this.count);

  int count = 0;

  // Sample: Stream (Firestore Realtime Update)
  static Stream<FS_Count> get stream {
    Stream<DocumentSnapshot> ss = FirebaseFirestore.instance
        .collection("devSettings")
        .doc("Counter1")
        .snapshots();
    return ss.asyncMap((DocumentSnapshot ds) =>
        FS_Count(int.parse(ds.get("count").toString())));
  }

  // Sample: transaction
  static void increment() {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("devSettings").doc("Counter1");
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      int count = snapshot.data()['count'] + 1;
      transaction.update(docRef, {'count': count});
      print(count);
    });
  }
}

// Sample: Stream (Firestore Realtime Update)
Stream<int> streamRunCommand() {
  return FirebaseFirestore.instance
      .collection("devSettings")
      .doc("AG1")
      .snapshots()
      .asyncMap((DocumentSnapshot ds) => int.parse(ds.get("run")));
}

class TestApp extends StateNotifier<int> {
  FirebaseFirestore fs = FirebaseFirestore.instance;

  TestApp() : super(0) {
    // 取得後に1回だけ通知
    fs.collection('devSettings').doc("Counter1").get().then((value) {
      print(value.data());
      state = value.get('count');
    }).catchError((e) => print("Error $e"));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    streamRunCommand().skip(1).forEach((runCount) {
      for (var i = 0; i < runCount; ++i) {
        FS_Count.increment();
      }
    });

    return MaterialApp(
      title: 'RIOT Mob',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamProvider<FS_Count>(
        create: (_) => FS_Count.stream,
        child: MyHomePage(title: 'RIOT Mob'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //int _counter = 0;

  void _incrementCounter() {
    //setState(() {
    // This call to setState tells the Flutter framework that something has
    // changed in this State, which causes it to rerun the build method below
    // so that the display can reflect the updated values. If we changed
    // _counter without calling setState(), then the build method would not be
    // called again, and so nothing would appear to happen.
    //_counter++;
    FS_Count.increment();
    FS_Count.increment();
    FS_Count.increment();
    FS_Count.increment();
    FS_Count.increment();
    FS_Count.increment();
    FS_Count.increment();
    FS_Count.increment();
    FS_Count.increment();
    FS_Count.increment();
    //});
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Consumer<FS_Count>(
                builder: (_, app, __) => Text(
                      (app != null) ? app.count.toString() : "Loading...",
                      style: Theme.of(context).textTheme.headline4,
                    )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
