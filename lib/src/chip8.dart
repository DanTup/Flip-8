import 'dart:collection';
import 'dart:math';
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
  HashSet<int> _pressedKeys = new HashSet<int>();

  final _rng = new Random();
  final List<List<bool>> _screenBuffer = new List<List<bool>>.generate(
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

  void keyDown(int key) {
    _pressedKeys.add(key);
  }

  void keyUp(int key) {
    _pressedKeys.remove(key);
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

  void _push(int value) {
    _stack[_sp++] = value;
  }

  int _pop() {
    return _stack[--_sp];
  }

  void _clearOrReturn(OpCodeData data) {
    if (data.nn == 0xE0) {
      for (var x = 0; x < screenWidth; x++) {
        for (var y = 0; y < screenHeight; y++) {
          _screenBuffer[x][y] = false;
        }
      }
    } else if (data.nn == 0xEE) {
      _pc = _pop();
    }
  }

  void _jump(OpCodeData data) {
    _pc = data.nnn;
  }

  void _callSubroutine(OpCodeData data) {
    _push(_pc);
    _pc = data.nnn;
  }

  void _skipIfXEqual(OpCodeData data) {
    if (_v[data.x] == data.nn) {
      _pc += 2;
    }
  }

  void _skipIfXNotEqual(OpCodeData data) {
    if (_v[data.x] != data.nn) {
      _pc += 2;
    }
  }

  void _skipIfXEqualY(OpCodeData data) {
    if (_v[data.x] == _v[data.y]) {
      _pc += 2;
    }
  }

  void _setX(OpCodeData data) {
    _v[data.x] = data.nn;
  }

  void _addX(OpCodeData data) {
    _v[data.x] += data.nn; // TODO: Do we need to handle overflow?
  }

  void _arithmetic(OpCodeData data) {
    switch (data.n) {
      case 0x0:
        _v[data.x] = _v[data.y];
        break;
      case 0x1:
        _v[data.x] |= _v[data.y];
        break;
      case 0x2:
        _v[data.x] &= _v[data.y];
        break;
      case 0x3:
        _v[data.x] ^= _v[data.y];
        break;
      case 0x4:
        // Set flag if we overflowed.
        _v[0xF] = _v[data.x] + _v[data.y] > 0xFF ? 1 : 0;
        _v[data.x] += _v[data.y];
        break;
      case 0x5:
        // Set flag if we underflowed.
        _v[0xF] = _v[data.x] > _v[data.y] ? 1 : 0;
        _v[data.x] -= _v[data.y];
        break;
      case 0x6:
        // Set flag if we shifted a 1 off the end.
        _v[0xF] = (_v[data.x] & 0x1) != 0 ? 1 : 0;
        _v[data.x] = _v[data.x] >> 1; // Shift right.
        break;
      case 0x7:
        // Set flag if we underflowed.
        _v[0xF] = _v[data.y] > _v[data.x] ? 1 : 0;
        _v[data.y] -= _v[data.x];
        break;
      case 0xE:
        // Set flag if we shifted a 1 off the end.
        _v[0xF] = (_v[data.x] & 0xF) != 0 ? 1 : 0;
        _v[data.x] = _v[data.x] << 1; // Shift left.
        break;
    }
  }

  void _skipIfXNotEqualY(OpCodeData data) {
    if (_v[data.x] != _v[data.x]) _pc += 2;
  }

  void _setI(OpCodeData data) {
    _i = data.nnn;
  }

  void _jumpWithOffset(OpCodeData data) {
    _pc = data.nnn + _v[0];
  }

  void _rnd(OpCodeData data) {
    _v[data.x] = _rng.nextInt(256) & data.nn;
  }

  void _drawSprite(OpCodeData data) {
    var startX = _v[data.x];
    var startY = _v[data.y];

    _v[0xF] = 0;
    for (var i = 0; i < data.n; i++) {
      var spriteLine = _ram[_i + i]; // A line of the sprite to render

      for (var bit = 0; bit < 8; bit++) {
        var x = (startX + bit) % screenWidth;
        var y = (startY + i) % screenHeight;

        var spriteBit = ((spriteLine >> (7 - bit)) & 1);
        var oldBit = _screenBuffer[x][y] ? 1 : 0;

        if (oldBit != spriteBit) _needsRedraw = true;

        // New bit is XOR of existing and new.
        var newBit = oldBit ^ spriteBit;

        if (newBit != 0) _screenBuffer[x][y] = true;

        // If we wiped out a pixel, set flag for collission.
        if (oldBit != 0 && newBit == 0) _v[0xF] = 1;
      }
    }
  }

  void _skipOnKey(OpCodeData data) {
    // 9E = IfKeyPressed
    // A1 = IfKeyNotPressed
    if ((data.nn == 0x9E && _pressedKeys.contains(_v[data.x])) ||
        (data.nn == 0xA1 && !_pressedKeys.contains(_v[data.x]))) {
      _pc += 2;
    }
  }

  void _misc(OpCodeData data) {
    if (_opCodesMisc.containsKey(data.nn)) {
      _opCodesMisc[data.nn](data);
    }
  }

  void _setXToDelay(OpCodeData data) {
    _v[data.x] = _delay;
  }

  void _waitForKey(OpCodeData data) {
    if (_pressedKeys.length != 0)
      _v[data.x] = _pressedKeys.first;
    else
      _pc -= 2;
  }

  void _setDelay(OpCodeData data) {
    _delay = _v[data.x];
  }

  void _setSound(OpCodeData data) {}
  void _addXToI(OpCodeData data) {
    _i += _v[data.x];
  }

  void _setIForChar(OpCodeData data) {
    // 0 is at 0x0, 1 is at 0x5, ...
    _i = _v[data.x] * 5;
  }

  void _binaryCodedDecimal(OpCodeData data) {
    _ram[_i + 0] = ((_v[data.x] / 100) % 10) as int;
    _ram[_i + 1] = ((_v[data.x] / 10) % 10) as int;
  }

  void _saveX(OpCodeData data) {
    for (var i = 0; i <= data.x; i++) {
      _ram[_i + i] = _v[i];
    }
  }

  void _loadX(OpCodeData data) {
    for (var i = 0; i <= data.x; i++) {
      _v[i] = _ram[_i + i];
    }
  }
}

class OpCodeData {
  int opCode;
  int nnn;
  int nn, x, y, n;
}
