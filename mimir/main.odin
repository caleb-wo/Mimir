package main

import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strings"


main :: proc(){
  args := os.args[1:]

  if len(args) > 1 {
    fmt.println("Usage: mimir [scipt].mmr")
    os.exit(64)
  } else if len(args) == 1 {
    run_file(args[0])
  } else {
    run_prompt()
  }
}

run_file :: proc(path: string) {
  if data, ok := os.read_entire_file(path, context.allocator); ok != nil{
    defer delete(data, context.allocator)
    run(string(data))
  } else {
    fmt.eprintfln("Error: Mimir couldn't read %s", path)
    os.exit(1)
  }
}

run_prompt :: proc() {
  stdin := os.stream_from_handle(os.stdin)

  reader: bufio.Reader
  bufio.reader_init(&reader, stdin)
  defer bufio.reader_destroy(&reader)

  for {
    fmt.print("|> ")
    _ = os.flush(os.stdout)

    if line, err := bufio.reader_read_string(&reader, '\n'); err != nil {
      line = strings.trim_space(line)

      if line == "" { continue }

      run(line)
    } else { break }
  }
}