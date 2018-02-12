import 'dart:typed_data';
import 'package:flip8/src/font.dart';

class Chip8 {
  static const int screenWidth = 64;
  static const int screenHeight = 32;

  bool _needsRedraw = false;
  Uint8List _v = new Uint8List(16);
  int _delay = 0;
  int _i = 0;
  int _pc = 0x200;
  int _sp = 0;
  Uint16List _stack = new Uint16List(16);
  Uint8List _ram = new Uint8List(0x1000);

  final List<List<bool>> _screenRows = new List<List<bool>>.generate(
      screenWidth, (_) => new List<bool>.filled(screenHeight, false),
      growable: false);
  Map<int, void Function(OpCodeData)> _opCodes;
  Map<int, void Function(OpCodeData)> _opCodesMisc;

  Chip8() {
    _writeFonts();

    _opCodes = <int, void Function(OpCodeData)>{
      0x0: _clearOrReturn,
      0x1: _jump,
      0x2: _callSubroutine,
      0x3: _skipIfXEqual,
      0x4: _skipIfXNotEqual,
      0x5: _skipIfXEqualY,
      0x6: _setX,
      0x7: _addX,
      0x8: _arithmetic,
      0x9: _skipIfXNotEqualY,
      0xA: _setI,
      0xB: _jumpWithOffset,
      0xC: _rnd,
      0xD: _drawSprite,
      0xE: _skipOnKey,
      0xF: _misc,
    };

    _opCodesMisc = <int, void Function(OpCodeData)>{
      0x07: _setXToDelay,
      0x0A: _waitForKey,
      0x15: _setDelay,
      0x18: _setSound,
      0x1E: _addXToI,
      0x29: _setIForChar,
      0x33: _binaryCodedDecimal,
      0x55: _saveX,
      0x65: _loadX,
    };
  }

  void loadProgram(Uint8List data) {}

  void tick() {
    // Read the two bytes of OpCode (big endian).
    var opCode = _ram[_pc++] << 8 | _ram[_pc++];

    // Split data into the possible formats the instruction might need.
    // https://en.wikipedia.org/wiki/CHIP-8#Opcode_table
    var op = new OpCodeData()
      ..opCode = opCode
      ..nnn = opCode & 0x0FFF
      ..nn = opCode & 0x00FF
      ..n = opCode & 0x000F
      ..x = (opCode & 0x0F00) >> 8
      ..y = (opCode & 0x00F0) >> 4;

    // Loop up the OpCode using the first nibble and execute.
    _opCodes[opCode >> 12](op);
  }

  void tick60Hz() {
    if (_delay > 0) _delay--;
    if (_needsRedraw) {
      _needsRedraw = false;
      _draw();
    }
  }

  void _draw() {}

  void _writeFonts() {
    var offset = 0x0;
    _writeFont(5 * offset++, Font.d0);
    _writeFont(5 * offset++, Font.d1);
    _writeFont(5 * offset++, Font.d2);
    _writeFont(5 * offset++, Font.d3);
    _writeFont(5 * offset++, Font.d4);
    _writeFont(5 * offset++, Font.d5);
    _writeFont(5 * offset++, Font.d6);
    _writeFont(5 * offset++, Font.d7);
    _writeFont(5 * offset++, Font.d8);
    _writeFont(5 * offset++, Font.d9);
    _writeFont(5 * offset++, Font.dA);
    _writeFont(5 * offset++, Font.dB);
    _writeFont(5 * offset++, Font.dC);
    _writeFont(5 * offset++, Font.dD);
    _writeFont(5 * offset++, Font.dE);
    _writeFont(5 * offset++, Font.dF);
  }

  void _writeFont(int address, int fontData) {
    _ram[address + 0] = (fontData & 0xF000000000) >> (8 * 4);
    _ram[address + 1] = (fontData & 0x00F0000000) >> (8 * 3);
    _ram[address + 2] = (fontData & 0x0000F00000) >> (8 * 2);
    _ram[address + 3] = (fontData & 0x000000F000) >> (8 * 1);
    _ram[address + 4] = (fontData & 0x00000000F0) >> (8 * 0);
  }

  void _clearOrReturn(OpCodeData data) {}
  void _jump(OpCodeData data) {}
  void _callSubroutine(OpCodeData data) {}
  void _skipIfXEqual(OpCodeData data) {}
  void _skipIfXNotEqual(OpCodeData data) {}
  void _skipIfXEqualY(OpCodeData data) {}
  void _setX(OpCodeData data) {}
  void _addX(OpCodeData data) {}
  void _arithmetic(OpCodeData data) {}
  void _skipIfXNotEqualY(OpCodeData data) {}
  void _setI(OpCodeData data) {}
  void _jumpWithOffset(OpCodeData data) {}
  void _rnd(OpCodeData data) {}
  void _drawSprite(OpCodeData data) {}
  void _skipOnKey(OpCodeData data) {}
  void _misc(OpCodeData data) {}
  void _setXToDelay(OpCodeData data) {}
  void _waitForKey(OpCodeData data) {}
  void _setDelay(OpCodeData data) {}
  void _setSound(OpCodeData data) {}
  void _addXToI(OpCodeData data) {}
  void _setIForChar(OpCodeData data) {}
  void _binaryCodedDecimal(OpCodeData data) {}
  void _saveX(OpCodeData data) {}
  void _loadX(OpCodeData data) {}
}

class OpCodeData {
  int opCode;
  int nnn;
  int nn, x, y, n;
}
