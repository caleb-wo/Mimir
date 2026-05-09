package main

import "core:fmt"
import "core:os"
import "core:os/path"
import "core:strings"

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
    data, ok := os.read_entire_file(file_path)
    if !ok {
        error(1, fmt.tprintf("Could not read file: %s", file_path))
        os.exit(74)
    }

    run(string(data))
    if had_error {
        os.exit(65)
    }
}

run_prompt :: proc() {
    for {
        fmt.print("#> ")
        line, ok := fmt.read_line(os.stdin)
        if !ok {
            return
        }
        run(line)
        had_error = false
    }
}

run :: proc(source: string) {
    scanner := scanner_init(source, context.allocator)
    scanner.scan_tokens()

    for token in scanner.tokens {
        fmt.println(token_to_string(token))
    }
}

error :: proc(line: int, message: string) {
    report(line, "", message)
}

report :: proc(line: int, at: string, message: string) {
    fmt.eprintfln("[Line: %d] Error%s: %s", line, at, message)
    had_error = true
}