import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state_notifier/state_notifier.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIOT Observer',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'RIOT Observer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirestoreForm queryForm = FirestoreForm('devLog');
  Stream<QuerySnapshot> dbSnapshot;

  @override
  Widget build(BuildContext context) {
    Query q = FirebaseFirestore.instance.collection(queryForm.collName.text);
    if (queryForm.where1.fsWhereField.text.isNotEmpty) {
      q = q.where(queryForm.where1.fsWhereField.text,
          isEqualTo: queryForm.where1.fsWhereValue.text);
    }
    dbSnapshot = q.snapshots();
    ObserverWidget observer = ObserverWidget(dbSnapshot);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            child: queryForm,
            padding: EdgeInsets.all(10),
          ),
          Expanded(
            child: observer,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          setState(() {
            //dbSnapshot = FirebaseFirestore.instance
            //    .collection(firestoreForm.fsCollection.text)
            //    .snapshots();
          });
        },
      ),
    );
  }
}

class FirestoreForm extends StatelessWidget {
  TextEditingController collName;

  TextEditingController fsOrderBy = TextEditingController(text: '');

  FirestoreForm(collectionName) {
    collName = TextEditingController(text: collectionName);
  }

  FsWhereForm where1 = FsWhereForm();

  @override
  Widget build(BuildContext context) {
    Widget collectionForm = TextField(
      controller: collName,
      decoration: InputDecoration(labelText: "collection"),
    );
    Widget orderByForm = TextFormField(
      initialValue: '',
      decoration: InputDecoration(labelText: "order by"),
    );
    return Form(
      child: Column(
        children: [
          collectionForm,
          where1,
          orderByForm,
        ],
      ),
    );
  }
}

class FsWhereForm extends StatelessWidget {
  TextEditingController fsWhereField = TextEditingController(text: '');
  TextEditingController fsWhereOp = TextEditingController(text: '==');
  TextEditingController fsWhereValue = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: fsWhereField,
            decoration: InputDecoration(labelText: 'Field Name'),
          ),
        ),
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: fsWhereOp,
            decoration: InputDecoration(
                labelText: 'Operator(<,<=,==,>,>=,array-contains)'),
          ),
        ),
        Expanded(
//          width: 100,
          child: TextFormField(
            controller: fsWhereValue,
            decoration: InputDecoration(labelText: 'Value'),
          ),
        ),
      ],
    );
  }
}

class ObserverWidget extends StatelessWidget {
  Stream<QuerySnapshot> dbSnapshot =
      FirebaseFirestore.instance.collection("devLogs").snapshots();

  ObserverWidget(this.dbSnapshot);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: dbSnapshot,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return GridView.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: snapshot.data.size,
            padding: EdgeInsets.all(2.0),
            itemBuilder: (BuildContext context, int index) {
              return Container(
                child: GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(snapshot.data.docs[index].id);
                    },
                    child: Column(
                      children: <Widget>[
                        Text(snapshot.data.docs[index].id),
                        Text(snapshot.data.docs[index].data().toString()),
                      ],
                    )),
                padding: EdgeInsets.all(2.0),
              );
            },
          );
        });
  }
}
