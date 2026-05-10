package main

import "core:fmt"
import "core:os"
import "core:bufio"

had_error : bool

main :: proc() {
    args := os.args
    if len(args) > 2 {
        fmt.println("Usage: mimir [script.mmr]")
        os.exit(64)
    } else if len(args) == 2 {
        run_file(args[1])
    } else {
        run_prompt()
    }
}

run_file :: proc(file_path: string) {
    data, err := os.read_entire_file_from_path(file_path, context.allocator); 
    
    if err != nil {
        fmt.eprintfln("[Line: 1] Error: Could not read file: %s", file_path)
        fmt.eprintfln("Message: %v", err)
        os.exit(74)
    }

    run(string(data))
    if had_error {
        os.exit(65)
    }
}

run_prompt :: proc() {
    reader: bufio.Reader
    bufio.reader_init(&reader, os.to_reader(os.stdin))
    defer bufio.reader_destroy(&reader)

    line_buf: [4096]byte
    for {
        fmt.print("#> ")
        n, err := bufio.reader_read(&reader, line_buf[:])
        if err != nil || n == 0 {
            return
        }
        line := string(line_buf[:n])
        // strip trailing newline
        if len(line) > 0 && line[len(line)-1] == '\n' {
            line = line[:len(line)-1]
        }
        run(line)
        had_error = false
    }
}

run :: proc(source: string) {
    scanner := scanner_init(source, context.allocator)
    scan_tokens(&scanner)

    for token in scanner.tokens {
        fmt.printfln("%v %s %v", token.token_type, token.lexeme, token.literal)
    }
}

error :: proc(line: int, message: string) {
    report(line, "", message)
}

report :: proc(line: int, at: string, message: string) {
    fmt.eprintfln("[Line: %d] Error%s: %s", line, at, message)
    had_error = true
}
