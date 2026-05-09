package main

Token :: struct {
    token_type : TokenType,
    lexeme     : string,
    literal    : Literal,
    line       : int,
}

Literal :: union {
    nil,
    bool,
    i64,
    f64,
    string,
}

token_to_string :: proc(t: Token) -> string {
    return fmt.tprintf("%v %s %v", t.token_type, t.lexeme, t.literal)
}
