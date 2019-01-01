import 'dart:async';
import 'dart:typed_data';

import 'package:flip8/src/chip8.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(new MyApp());

class Flip8 extends StatefulWidget {
  Flip8({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _Flip8State createState() => new _Flip8State();
}

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

class _Flip8State extends State<Flip8> {
  _Flip8State() {
    currentFrame = new Image.asset('assets/blank.png', fit: BoxFit.contain);
    _reset();
  }

  Chip8 chip8;
  Image currentFrame;
  Timer tickTimer60Hz;
  Timer tickTimer;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          currentFrame,
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _makeButton("1", 0x1),
              _makeButton("2", 0x2),
              _makeButton("3", 0x3),
              _makeButton("4", 0x4),
            ],
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _makeButton("4", 0x4),
              _makeButton("5", 0x5),
              _makeButton("6", 0x6),
              _makeButton("D", 0xD),
            ],
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _makeButton("7", 0x7),
              _makeButton("8", 0x8),
              _makeButton("9", 0x9),
              _makeButton("E", 0xE),
            ],
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _makeButton("A", 0xA),
              _makeButton("0", 0x0),
              _makeButton("B", 0xB),
              _makeButton("F", 0xF),
            ],
          ),
          new RaisedButton(child: Text("Reset"), onPressed: _reset),
          new Text(
            "FLIP-8 by DanTup",
            textAlign: TextAlign.center,
            style: new TextStyle(fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget _makeButton(String text, int keyValue) {
    return new GestureDetector(
      child: new RaisedButton(
        child: Text(text),
        // TODO: This makes buttons look disable, but else onTapUp doesn't fire
        onPressed: null,
      ),
      onTapDown: (_) => chip8.keyDown(keyValue),
      onTapUp: (_) => chip8.keyUp(keyValue),
    );
  }

  void _reset() {
    if (tickTimer60Hz != null) tickTimer60Hz.cancel();
    if (tickTimer != null) tickTimer.cancel();
    chip8 = new Chip8((Uint8List frameData) {
      setState(() {
        currentFrame = new Image.memory(
          frameData,
          gaplessPlayback: true,
          fit: BoxFit.contain,
        );
      });
    });
    rootBundle.load('assets/breakout.ch8').then((bytes) {
      chip8.loadProgram(bytes.buffer.asUint8List());
      tickTimer60Hz = new Timer.periodic(
          new Duration(milliseconds: 17), (_) => chip8.tick60Hz());
      tickTimer = new Timer.periodic(
          new Duration(milliseconds: 1), (_) => chip8.tick());
    });
  }
}
