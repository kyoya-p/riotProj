import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:provider/provider.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/Bell.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:state_notifier/state_notifier.dart';

class FsCount {
  FsCount(this.count);

  int count = 0;

  // Sample: Stream (Firestore Realtime Update)
  static Stream<FsCount> get stream {
    Stream<DocumentSnapshot> ss = FirebaseFirestore.instance
        .collection("devConfig")
        .doc("Counter1")
        .snapshots();
    return ss.asyncMap((DocumentSnapshot ds) =>
        FsCount(int.parse(ds.get("count").toString())));
  }

  // Sample: transaction
  static void increment() {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("devConfig").doc("Counter1");
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      int count = snapshot.data()['count'] + 1;
      transaction.update(docRef, {'count': count});
      print("INC: $count");
    });
  }
}

// Sample: Stream (Firestore Realtime Update)
Stream<int> streamRunCommand() {
  return FirebaseFirestore.instance
      .collection("devConfig")
      .doc("AG1")
      .snapshots()
      .asyncMap((DocumentSnapshot ds) => int.parse(ds.get("run")));
}

class TestApp extends StateNotifier<int> {
  FirebaseFirestore fs = FirebaseFirestore.instance;

  TestApp() : super(0) {
    // 取得後に1回だけ通知
    fs.collection('devConfig').doc("Counter1").get().then((value) {
      print(value.data());
      state = value.get('count');
      // ignore: return_of_invalid_type_from_catch_error
    }).catchError((e) => print("Error $e"));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    streamRunCommand().skip(1).forEach((runCount) {
      for (var i = 0; i < runCount; ++i) {
        FsCount.increment();
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
      home: StreamProvider<FsCount>(
        create: (_) => FsCount.stream,
        child: MyHomePage(title: 'RIOT Mob'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

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
    FsCount.increment();
    FsCount.increment();
    FsCount.increment();
    FsCount.increment();
    FsCount.increment();
    FsCount.increment();
    FsCount.increment();
    FsCount.increment();
    FsCount.increment();
    FsCount.increment();
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
        actions: [bell(context)],
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
            Consumer<FsCount>(
                builder: (_, app, __) => Text(
                      app.count.toString(),
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
