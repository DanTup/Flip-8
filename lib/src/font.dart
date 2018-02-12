class Font {
  // Fonts are 4x5. Each line must be a byte wide so is stored in the upper
  // 4 bits of the byte (xxxx0000).
  // Eg:
  //     0:
  //         ####  =  1111  =  F0
  //         #  #  =  1001  =  90
  //         #  #  =  1001  =  90
  //         #  #  =  1001  =  90
  //         ####  =  1111  =  F0

  static const int d0 = 0xF0909090F0;
  static const int d1 = 0x2060202070;
  static const int d2 = 0xF010F080F0;
  static const int d3 = 0xF010F010F0;
  static const int d4 = 0x9090F01010;
  static const int d5 = 0xF080F010F0;
  static const int d6 = 0xF080F090F0;
  static const int d7 = 0xF010204040;
  static const int d8 = 0xF090F090F0;
  static const int d9 = 0xF090F010F0;
  static const int dA = 0xF090F09090;
  static const int dB = 0xE090E090E0;
  static const int dC = 0xF0808080F0;
  static const int dD = 0xE0909090E0;
  static const int dE = 0xF080F080F0;
  static const int dF = 0xF080F08080;
}
