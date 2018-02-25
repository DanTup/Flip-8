import 'dart:async';
import 'dart:typed_data';

import 'package:flip8/src/chip8.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  Chip8 chip8;
  Image currentFrame;
  Timer tickTimer60Hz;
  Timer tickTimer;

  static final double screenWidth = Chip8.screenWidth.toDouble();
  static final double screenHeight = Chip8.screenHeight.toDouble();

  _Flip8State() {
    currentFrame = new Image.asset('assets/blank.png', fit: BoxFit.contain);
    chip8 = new Chip8((Uint8List frameData) {
      setState(() {
        currentFrame = new Image.memory(
          frameData,
          width: screenWidth,
          height: screenHeight,
          gaplessPlayback: true,
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
