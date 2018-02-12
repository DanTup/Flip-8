import 'package:flip8/src/chip8.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'FLIP-8',
      home: new Flip8(title: "FLIP-8"),
    );
  }
}

class Flip8 extends StatefulWidget {
  Flip8({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _Flip8State createState() => new _Flip8State();
}

class _Flip8State extends State<Flip8> {
  Chip8 chip8 = new Chip8();
  Image currentFrame;

  _Flip8State() {
    currentFrame = new Image.asset('assets/blank.png', fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[currentFrame],
      ),
    );
  }
}
