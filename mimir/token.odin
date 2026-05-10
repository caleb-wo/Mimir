package main

Token :: struct {
    token_type : TokenType,
    lexeme     : string,
    literal    : Literal,
    line       : int,
}

Literal :: union {
    bool,
    i64,
    f64,
    string,
}
