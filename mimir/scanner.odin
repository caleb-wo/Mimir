package main

import "core:fmt"
import "core:mem"
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
        source   = source,
        tokens   = make([dynamic]Token, allocator),
        start    = 0,
        current  = 0,
        line     = 1,
        keywords = make(map[string]TokenType, allocator),
    }

    s.keywords["and"]     = .And
    s.keywords["or"]      = .Or
    s.keywords["not"]     = .Not
    s.keywords["bind"]    = .Bind
    s.keywords["if"]      = .If
    s.keywords["else"]    = .Else
    s.keywords["while"]   = .While
    s.keywords["process"] = .Process
    s.keywords["return"]  = .Return
    s.keywords["true"]    = .True
    s.keywords["false"]   = .False
    s.keywords["nil"]     = .Nil
    s.keywords["is"]      = .Is
    s.keywords["isnt"]    = .Isnt

    return s
}

scan_tokens :: proc(s: ^Scanner) {
    for !is_at_end(s) {
        s.start = s.current
        scan_token(s)
    }

    add_token(s, .EOF, nil)
}

is_at_end :: proc(s: ^Scanner) -> bool {
    return s.current >= len(s.source)
}

scan_token :: proc(s: ^Scanner) {
    c := advance(s)

    switch c {
    case '(':
        add_token(s, .LeftParen)
    case ')':
        add_token(s, .RightParen)
    case '{':
        add_token(s, .LeftBrace)
    case '}':
        add_token(s, .RightBrace)
    case ',':
        add_token(s, .Comma)
    case '+':
        add_token(s, .Plus)
    case '*':
        add_token(s, .Star)
    case '/':
        add_token(s, .Slash)
    case '#':
        add_token(s, .Hash)
    case '=':
        add_token(s, .Equal)
    case '<':
        if match_char(s, '=') {
            add_token(s, .LessEqual)
        } else {
            add_token(s, .Less)
        }
    case '>':
        if match_char(s, '=') {
            add_token(s, .GreaterEqual)
        } else {
            add_token(s, .Greater)
        }
    case '-':
        if match_char(s, '-') {
            for !is_at_end(s) && peek(s) != '\n' {
                _ = advance(s)
            }
        } else {
            add_token(s, .Minus)
        }
    case ' ', '\r', '\t':
        // ignore
    case '\n':
        s.line += 1
    case '"':
        scan_string(s)
    case:
        if is_digit(c) {
            number(s)
        } else if is_alpha(c) {
            identifier(s)
        } else {
            error(s.line, fmt.tprintf("Unexpected character: '%c'.", c))
        }
    }
}

// advance reads the next byte from source and returns it as a u8.
// The scanner operates at the byte level; source is expected to be
// ASCII for identifiers/keywords, and string literals are stored as
// raw byte slices without re-encoding.
advance :: proc(s: ^Scanner) -> u8 {
    ch := s.source[s.current]
    s.current += 1
    return ch
}

match_char :: proc(s: ^Scanner, expected: u8) -> bool {
    if is_at_end(s) || s.source[s.current] != expected {
        return false
    }
    s.current += 1
    return true
}

peek :: proc(s: ^Scanner) -> u8 {
    if is_at_end(s) {
        return 0
    }
    return s.source[s.current]
}

peek_next :: proc(s: ^Scanner) -> u8 {
    if s.current + 1 >= len(s.source) {
        return 0
    }
    return s.source[s.current + 1]
}

is_digit :: proc(c: u8) -> bool {
    return c >= '0' && c <= '9'
}

is_alpha :: proc(c: u8) -> bool {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') ||
           c == '_'
}

is_alpha_numeric :: proc(c: u8) -> bool {
    return is_alpha(c) || is_digit(c)
}

scan_string :: proc(s: ^Scanner) {
    for peek(s) != '"' && !is_at_end(s) {
        if peek(s) == '\n' {
            s.line += 1
        }
        _ = advance(s)
    }

    if is_at_end(s) {
        error(s.line, "Unterminated string.")
        return
    }

    _ = advance(s)
    value := s.source[s.start+1 : s.current-1]
    add_token(s, .String, value)
}

number :: proc(s: ^Scanner) {
    for is_digit(peek(s)) {
        _ = advance(s)
    }

    is_float := false
    if peek(s) == '.' && is_digit(peek_next(s)) {
        is_float = true
        _ = advance(s)
        for is_digit(peek(s)) {
            _ = advance(s)
        }
    }

    text := s.source[s.start:s.current]

    if is_float {
        f, ok := strconv.parse_f64(text)
        if !ok {
            error(s.line, "Invalid float literal.")
            return
        }
        add_token(s, .Float, f)
    } else {
        i, ok := strconv.parse_i64(text)
        if !ok {
            error(s.line, "Invalid integer literal.")
            return
        }
        add_token(s, .Integer, i)
    }
}

identifier :: proc(s: ^Scanner) {
    for is_alpha_numeric(peek(s)) {
        _ = advance(s)
    }

    text := s.source[s.start:s.current]
    if t, ok := s.keywords[text]; ok {
        add_token(s, t)
    } else {
        add_token(s, .Identifier)
    }
}

add_token :: proc(s: ^Scanner, token_type: TokenType, literal: Literal = nil) {
    text := s.source[s.start:s.current]
    append(&s.tokens, Token{
        token_type = token_type,
        lexeme     = text,
        literal    = literal,
        line       = s.line,
    })
}
