package tree.walk.mimir

enum TokenType:
  // Single-character tokens
  case LeftParen, RightParen, LeftBrace, RightBrace, Comma
  case Minus, Plus, Slash, Star
  case Hash

  // Multichar tokens
  case Equal, Less, LessEqual, Greater, GreaterEqual
  case Is, Isnt // Mimir's == and !=

  // Literals
  case Identifier, String, Integer, Float

  // Keywords
  case And, Or, Not
  case Bind, If, Else, While, Process, Return
  case True, False, Nil
  case Print

  case EOF

end TokenType