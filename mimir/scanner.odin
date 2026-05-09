package main

import "core:fmt"
import "core:strings"
import "core:strconv"

Scanner :: struct {
    source    : string,
    tokens    : [dynamic]Token,
    start     : int,
    current   : int,
    line      : int,
    keywords  : map[string]TokenType,
}

scanner_init :: proc(source: string, allocator: mem.Allocator) -> Scanner {
    s := Scanner{
        source = source,
        tokens = make([dynamic]Token, 0, allocator),
        start = 0,
        current = 0,
        line = 1,
        keywords = make(map[string]TokenType),
    }

    s.keywords["and"] = .And
    s.keywords["or"] = .Or
    s.keywords["not"] = .Not
    s.keywords["bind"] = .Bind
    s.keywords["if"] = .If
    s.keywords["else"] = .Else
    s.keywords["while"] = .While
    s.keywords["process"] = .Process
    s.keywords["return"] = .Return
    s.keywords["true"] = .True
    s.keywords["false"] = .False
    s.keywords["nil"] = .Nil
    s.keywords["is"] = .Is
    s.keywords["isnt"] = .Isnt

    return s
}

scan_tokens :: proc(s: ^Scanner) {
    for !s.is_at_end() {
        s.start = s.current
        s.scan_token()
    }

    s.add_token(.EOF, Literal{nil = {} })
}

is_at_end :: proc(s: ^Scanner) -> bool {
    return s.current >= len(s.source)
}

scan_token :: proc(s: ^Scanner) {
    c := s.advance()

    switch c {
    case '(':
        s.add_token(.LeftParen, {})
    case ')':
        s.add_token(.RightParen, {})
    case '{':
        s.add_token(.LeftBrace, {})
    case '}':
        s.add_token(.RightBrace, {})
    case ',':
        s.add_token(.Comma, {})
    case '+':
        s.add_token(.Plus, {})
    case '*':
        s.add_token(.Star, {})
    case '/':
        s.add_token(.Slash, {})
    case '#':
        s.add_token(.Hash, {})
    case '=':
        s.add_token(.Equal, {})
    case '<':
        if s.match_char('=') {
            s.add_token(.LessEqual, {})
        } else {
            s.add_token(.Less, {})
        }
    case '>':
        if s.match_char('=') {
            s.add_token(.GreaterEqual, {})
        } else {
            s.add_token(.Greater, {})
        }
    case '-':
        if s.match_char('-') {
            for !s.is_at_end() && s.peek() != '\n' {
                _ = s.advance()
            }
        } else {
            s.add_token(.Minus, {})
        }
    case ' ', '\r', '\t':
        // ignore
    case '\n':
        s.line += 1
    case '"':
        s.string()
    case:
        if is_digit(c) {
            s.number()
        } else if is_alpha(c) {
            s.identifier()
        } else {
            error(s.line, fmt.tprintf("Unexpected character: '%c'.", c))
        }
    }
}

advance :: proc(s: ^Scanner) -> rune {
    ch := rune(s.source[s.current])
    s.current += 1
    return ch
}

match_char :: proc(s: ^Scanner, expected: rune) -> bool {
    if s.is_at_end() || rune(s.source[s.current]) != expected {
        return false
    }
    s.current += 1
    return true
}

peek :: proc(s: ^Scanner) -> rune {
    if s.is_at_end() {
        return 0
    }
    return rune(s.source[s.current])
}

peek_next :: proc(s: ^Scanner) -> rune {
    if s.current + 1 >= len(s.source) {
        return 0
    }
    return rune(s.source[s.current + 1])
}

is_digit :: proc(c: rune) -> bool {
    return c >= '0' && c <= '9'
}

is_alpha :: proc(c: rune) -> bool {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') ||
           c == '_'
}

is_alpha_numeric :: proc(c: rune) -> bool {
    return is_alpha(c) || is_digit(c)
}

string :: proc(s: ^Scanner) {
    for s.peek() != '"' && !s.is_at_end() {
        if s.peek() == '\n' {
            s.line += 1
        }
        _ = s.advance()
    }

    if s.is_at_end() {
        error(s.line, "Unterminated string.")
        return
    }

    _ = s.advance()
    value := s.source[s.start+1 : s.current-1]
    s.add_token(.String, Literal{string = value})
}

number :: proc(s: ^Scanner) {
    for is_digit(s.peek()) {
        _ = s.advance()
    }

    is_float := false
    if s.peek() == '.' && is_digit(s.peek_next()) {
        is_float = true
        _ = s.advance()
        for is_digit(s.peek()) {
            _ = s.advance()
        }
    }

    text := s.source[s.start:s.current]

    if is_float {
        f, ok := strconv.parse_f64(text)
        if !ok {
            error(s.line, "Invalid float literal.")
            return
        }
        s.add_token(.Float, Literal{f64 = f})
    } else {
        i, ok := strconv.parse_i64(text)
        if !ok {
            error(s.line, "Invalid integer literal.")
            return
        }
        s.add_token(.Integer, Literal{i64 = i})
    }
}

identifier :: proc(s: ^Scanner) {
    for is_alpha_numeric(s.peek()) {
        _ = s.advance()
    }

    text := s.source[s.start:s.current]
    if t, ok := s.keywords[text]; ok {
        s.add_token(t, {})
    } else {
        s.add_token(.Identifier, {})
    }
}

add_token :: proc(s: ^Scanner, token_type: TokenType, literal: Literal = {}) {
    text := s.source[s.start:s.current]
    append(&s.tokens, Token{
        token_type = token_type,
        lexeme = text,
        literal = literal,
        line = s.line,
    })
}
