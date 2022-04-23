// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MultiSelectPage(
        title: 'Flutter Demo Home Page',
        itemBuilder: (_, index) {
          if (index > 200) return null;
          return Text(index.toString());
        },
      ),
    );
  }
}

class MultiSelectPage extends StatefulWidget {
  MultiSelectPage({Key key, this.title, this.itemBuilder}) : super(key: key);

  final String title;
  final IndexedWidgetBuilder itemBuilder;

  @override
  _MultiSelectPageState createState() => _MultiSelectPageState();
}

class _MultiSelectPageState extends State<MultiSelectPage> {
  //List<String> _imageList = List();
  List<int> _selectedIndexList = [];
  bool _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> _buttons = [];
    if (_selectionMode) {
      _buttons.add(IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            _selectedIndexList.sort();
            print(
                'Delete ${_selectedIndexList.length} items! Index: ${_selectedIndexList.toString()}');
          }));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: _buttons,
      ),
      body: _createBody(),
    );
  }

  @override
  void initState() {
    super.initState();
//    _imageList.add('https://picsum.photos/800/600/?image=280');
//    _imageList.add('https://picsum.photos/800/600/?image=281');
//    _imageList.add('https://picsum.photos/800/600/?image=282');
//    _imageList.add('https://picsum.photos/800/600/?image=283');
//    _imageList.add('https://picsum.photos/800/600/?image=284');
  }

  void _changeSelection({bool enable, int index}) {
    _selectionMode = enable;
    _selectedIndexList.add(index);
    if (index == -1) {
      _selectedIndexList.clear();
    }
  }

  Widget _createBody() {
    return StaggeredGridView.builder(
      //crossAxisCount: 3,
      //mainAxisSpacing: 4.0,
      //crossAxisSpacing: 4.0,
      gridDelegate: SliverStaggeredGridDelegateWithMaxCrossAxisExtent(
        staggeredTileCount: 1,
        maxCrossAxisExtent: 1,
        staggeredTileBuilder: (index) => StaggeredTile.count(1, 1),
      ),

      primary: false,
      itemCount: null,
      itemBuilder: (BuildContext context, int index) {
        //if (index >= _imageList.length) return null;
        return getGridTile(index);
      },
      //staggeredTileBuilder: (int index) => StaggeredTile.count(1, 0.5),
      padding: const EdgeInsets.all(4.0),
    );
  }

  GridTile getGridTile(int index) {
    Widget item = widget.itemBuilder(context, index);
    if (item == null) return null;

    if (_selectionMode) {
      return GridTile(
          header: GridTileBar(
            leading: Icon(
              _selectedIndexList.contains(index)
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
              color: _selectedIndexList.contains(index)
                  ? Colors.green
                  : Colors.black,
            ),
          ),
          child: GestureDetector(
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue[50], width: 0.0)),
              child: item,
            ),
            onLongPress: () {
              setState(() {
                _changeSelection(enable: false, index: -1);
              });
            },
            onTap: () {
              setState(() {
                if (_selectedIndexList.contains(index)) {
                  _selectedIndexList.remove(index);
                } else {
                  _selectedIndexList.add(index);
                }
              });
            },
          ));
    } else {
      return GridTile(
        child: InkResponse(
          child: item,
          onLongPress: () {
            setState(() {
              _changeSelection(enable: true, index: index);
            });
          },
        ),
      );
    }
  }
}
