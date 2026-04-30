# Mimir — Language Specification

<sub>(If Mimir is being <em><strong>seriously</strong></em> used somewhere, please let me know & I'll get back to workshopping.)</sub>

---

## 1. Overview & Philosophy

Mimir (_named after the Norse god: [Mímir](https://en.wikipedia.org/wiki/Mímir)_) is a dynamic, tree-walk interpreted language implemented in [Odin](https://odin-lang.org/). I understand tree-walking is not performant. This is to meet the immediate requirements of my senior project at BYU–Idaho. Following the MVP, I plan to refactor the Odin backend into a stack-based bytecode virtual machine to significantly reduce execution overhead and explore lower-level optimization techniques.

Mimir features lexical closures & first-class citizenship for processes (functions). It was developed by applying what I learned from Lox, the language by Robert Nystrom featured in [Crafting Interpreters](https://www.craftinginterpreters.com/the-lox-language.html). It will **not** support object-oriented programming. In Mimir, data & logic are separate.

### Goals

1. **Learning**: As a Software Engineering student at BYU–Idaho, this senior project serves as my springboard into the deep well of programming language research, interpreter architecture, & compiler engineering — things I've been intrigued by for a long time.
2. **Data-Oriented Syntax**: Mimir's syntax is planned to be honest, directly representing the movement & transformation of data under the hood to the best I can. It utilizes a fundamentally C-styled syntax, but introduces unique differences to highlight data flow. It also favors conversational operators (`is`, `isnt`, `not`, `and`, `or`) to improve scripting ergonomics.
3. **Simple**: This language should be small & tight enough that it's easy to learn & get rolling with. It's a scripting language after all.

---

## 2. Error Handling

For the MVP, Mimir uses **hard runtime errors with clear line numbers**. There is no exception handling, no `try`/`catch`, and no error recovery. If something goes wrong, the program crashes immediately and reports exactly where.

```
[Runtime Error] Line 4: Cannot apply operator '*' to types "string" and "integer".
```

This is the honest tradeoff for a tree-walk interpreter at this stage. The goal is that errors are never silent and never cryptic, that way you always know the line, and you always know why. Future iterations may introduce softer error recovery, but for now: crash fast, crash clearly.

Examples of hard runtime errors:

```lua
"Hello" * 5       -- [Runtime Error] Line 1: Cannot apply operator '*' to types "string" and "integer".
10 / 0            -- [Runtime Error] Line 1: Division by zero.
bind x = nil
x + 1             -- [Runtime Error] Line 3: Cannot apply operator '+' to types "nil" and "integer".
```

---

## 3. Lexical Grammar

### Comments

Mimir supports single-line & multiline comments. Multiline comments can be nested.

```clojure
-- This is a single-line comment.

--(
  This is a multiline comment.
  --(
    Comments can be nested.
  )--
)--
```

### Identifiers & Reserved Words

Identifiers follow standard rules: they begin with a letter or underscore and may contain letters, digits, and underscores. The following are reserved keywords:

`bind`, `return`, `if`, `else`, `unless`, `for`, `while`, `until`, `match`, `case`, `default`, `cycle`, `break`, `continue`, `process`, `toolset`, `true`, `false`, `nil`, `and`, `or`, `not`, `is`, `isnt`, `in`, `as`, `select`, `spare`

### Special Prefixes

- **`#`** — Reserved for **directives**: engine-level instructions like `#print`, `#const`, `#global`, `#import`. Users cannot define identifiers starting with `#`.
- **`$`** — Reserved for **system toolsets**: `$str`, `$list`, `$math`, etc. Users cannot use `$` in any identifier.

---

## 4. Type System

Mimir is dynamically typed. Under the hood, it tracks 10 distinct types. `$type.of(n)` returns a string representation of the type of `n`. `$type.all()` returns the full list:

```lua
["string", "integer", "float", "boolean", "list", "map", "range", "process", "toolset", "nil"]
```

There are many tools for working with types in the `$type` system toolset. You'll read about toolsets in the section on Processes.

### Nil

In Mimir, "nothing" is represented simply:

```lua
bind amount_of_cookies = nil -- 😢
```

### Booleans

Mimir has two Boolean values: `true` & `false`.

### Integers & Floats

Numbers can be either integers or floating-point. Mimir differentiates between the two. They are raw primitives, not objects.

```lua
bind integer = 10
bind float   = 10.10
```

> ❗️ When performing arithmetic between an integer and a float, the integer is promoted to float under the hood for convenience. A float is **never** demoted for any reason. This is the **only** place in the whole language where an implicit type conversion will happen.

### Strings

Strings are denoted with double quotes. Mimir supports string interpolation via `#|...|` syntax. Strings are raw primitives, not objects.

```lua
bind name      = "Mímir"
bind greeting  = "Hello from #|name|!"
bind greeting2 = "Hello from " + name + "!"
bind example   = "#|name| is over #| 2500 * 2 | years old."

name[0] is "M" -- true
```

> String interpolation will first be implemented through desugaring. Once MVP is hit, this process will be optimized.

### Lists

Mimir includes dynamic lists. Accessing outside a list's boundary returns `nil`.

```lua
bind list = ["Item 1", "Item 2", 3, 55.55]
(list[0] is "Item 1") -- true
(list[100] is nil)    -- true

$list.push(list, "Item 3")
```

By default, lists can hold any type. For performance & memory efficiency, you can type a list using the `#` directive. The type is inferred from the first element, or declared explicitly.

```lua
bind typed_list = #["Value 1", "Value 2"] -- assumes string
$list.push(typed_list, 25) -- [Runtime Error]: typed_list is typed to "string" but received "integer".

bind empty_strings  = #string[]  -- empty, locked to string
bind empty_ints     = #integer[]
bind empty_floats   = #float[]
```

### Maps

Mimir supports dynamic **unordered** key-value data structures called Maps, declared with JSON-style curly braces `{}`. Trailing/hanging commas are fully supported to keep diffs clean.

Maps can hold any value, including processes. Mimir does **not** support dot-access on maps — only bracket access. (Dot access is reserved for toolsets.)

```lua
bind map = {
  "first_name": "SpongeBob",
  "age": 40,
}
map["last_name"] = "SquarePants"
map["age"] = 39

#print map["first_name"] -- SpongeBob
```

### Range

Mimir has a dedicated range type. `..` is exclusive of the right bound; `...` is inclusive.

```lua
for i in 0..10  {} -- 0 to 9
for i in 0...10 {} -- 0 to 10
```

Ranges can be stored as values, reversed, and used with negatives:

```lua
bind my_range            = 0..100
bind reverse_range       = 50..0    -- counts down from 50 to 1
bind negative_range      = -10...17 -- counts from -10 to 17

for i in my_range {} -- Legal
```

Counts always flow left to right:

```lua
0..50    -- counts up
50..0    -- counts down
-4..-100 -- counts down
-100..-4 -- counts up
```

Ranges can slice lists & strings:

```lua
bind list     = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
bind example1 = list[2..5]  -- [3, 4, 5]   (index 5 excluded)
bind example2 = list[2...5] -- [3, 4, 5, 6] (index 5 included)
```

The range operator requires two integer values — literals, variable bindings, or process results. For iterating over collections, prefer the native `for key_or_index, val in collection` syntax.

```lua
for idx, _ in my_list {}              -- Preferred
for idx in 0..$list.size(list) {}     -- Non-idiomatic
```

Ranges can be passed to processes:

```lua
bind entity_range = 1...calculate_enemy_count(GAME_DIFFICULTY_SETTING)

process spawn_enemies(entity_range) {
  cycle entity_range {
    -- work
  }
}
```

### Process

Processes (functions) are a first-class type in Mimir. See **Section 8** for full details.

### Toolset

Toolsets are static, named modules of associated processes. They are **not** first-class citizens. See **Section 8** for full details.

---

## 5. Variables & Bindings

Variables are declared using the `bind` keyword, emphasizing the attachment of data to a reference. A variable declared without an initializer defaults to `nil`. Mimir supports comma-separated multi-declarations.

```lua
bind value  = "Hello!"
bind value2 -- nil
bind value3, value4, value5
```

### Modifiers

Variable declarations can be modified with directives to alter their state or scope:

- **`#const`** — Locks the variable, preventing reassignment. Use `SCREAMING_SNAKE_CASE` by convention.
- **`#global`** — Explicitly hoists the variable to the global environment. Use the `G_` prefix by convention.

```lua
#const bind FIXED_VALUE  = "I will never change!"
#global bind G_app_state = "I am everywhere."
```

### Scoping & Shadowing

Mimir uses lexical scoping. Inner scopes can declare variables with the same name as outer scopes without affecting the original — the interpreter resolves names by searching from the innermost scope outward.

```lua
process outer() {
  bind a = "Hello!"
  process inner() {
    bind a = "Hola!" -- shadows outer 'a'
    #print a
  }
  return inner
}

bind ps = outer()
ps() -- prints "Hola!"
```

---

## 6. Expressions

### Arithmetic

Mimir features standard arithmetic. The `%` operator calculates the **true Euclidean modulus** rather than a C-style remainder (e.g., `-5 % 3` evaluates to `1`, not `-2`).

```lua
bind result = add + me
result = subtract - me
result = multiply * me
result = divide / me
result = modulus % me
-make_me_negative
```

### Comparison & Equality

Standard comparison operators return a Boolean and can only be used on numbers:

```lua
less < than
less_than <= or_equal
greater > than
greater_than >= or_equal

$str.size(str_one) > $str.size(str_two)
```

The equality operators `is` & `isnt` (equivalent to `==` & `!=` in other languages) can be used on **any two values**, including type checks:

```lua
5 is 5             -- true
5 is 5.0           -- false (integer vs. float)
"Thor" isnt "Zeus" -- true
"Hi" is "Hi"       -- true

bind value1 = ""
bind value2 = 18
$type.of(value1) is $type.of(value2) -- false: "string" == "integer"
```

### Logical Operators

`not`, `and`, & `or` are the logical operators. Both `and` & `or` are short-circuiting.

```lua
not true  -- false
not false -- true

true and true   -- true
true and false  -- false
i_am_false() and i_am_true() -- SHORTCIRCUIT: i_am_true() is never called.

true or true    -- true
false or true   -- true
i_am_true() or i_am_false() -- SHORTCIRCUIT: i_am_false() is never called.
```

### Select / Spare (Ternary)

`select / spare` is Mimir's ternary expression. It resolves to a single value and is legal anywhere a value is expected. Wrap in parentheses when combined with other math to avoid ambiguity; elsewhere, parentheses are optional.

```lua
bind x = condition select 10 spare 5  -- 10 if true, 5 otherwise

-- In math:
5 + (cond select 10 spare 0)

-- In process arguments:
saveStatus(is_active select "Success" spare "Error")

-- In a return:
process get_status() { return is_active select 1 spare 0 }

-- In a list:
bind scores = [100, has_bonus select 50 spare 10, 0]
```

### The Capture Operator (`>>`)

The `>>` operator creates a scoped alias of the matched value inside a `match` case block. See **Section 7 — Match** for full details.

---

## 7. Control Flow

### If

```lua
if condition {
  #print "yes"
} else if other_condition {
  #print "other yes"
} else {
  #print "no"
}
```

### Unless

`unless` is best used for quick negative guards. It is restricted to a single branch — no `else`.

```lua
unless condition {
  #print "no"
}
```

### Match

The `match` statement is a powerful, readable alternative to complex `if-else-if` chains. For the MVP, it is implemented as syntactic sugar for `if-else-if` equality checks. In future iterations, I plan to transition to **true structural pattern matching** with a dedicated `Match` instruction in the bytecode VM, enabling destructuring binds & type-guarded patterns.

Key features:

- **No Fallthrough**: Cases are mutually exclusive. Once a match is found and its block executes, the interpreter exits the statement.
- **Multi-Match**: Multiple values can be matched to a single block using a comma-separated list.

```lua
match condition {
  case 200:
    #print "Success"
  case 400, 404:
    #print "Client Error."
  case 500:
    #print "Server Error."
  default:
    #print "Unknown Status"
}
```

Because `$type.of()` returns a string, you can match on type:

```lua
match $type.of(thing) {
  case "string":  #print "#|thing| is a string!"
  case "integer": #print "#|thing| is an integer!"
  case "float":   #print "#|thing| is a float!"
}
```

#### The Capture Operator (`>>`)

The `>>` operator creates a **scoped reference** (not a copy) to the matched value, accessible by a given name within the `case` block:

```lua
match http_status {
  case 400, 401, 403, 404 >> error_code:
    #print "Client failure: #|error_code|"
  default >> unknown_code:
    #print "Unknown code, #|unknown_code|, of type: #| $type.of(unknown_code) |"
}
```

### For

Mimir has `for...in` loops. They work over ranges, lists, maps, and strings.

```lua
-- Range syntax
for i in 0..100  {} -- 0 to 99
for i in 0...100 {} -- 0 to 100
for i in 100..0  {} -- reverse range

-- Collection iteration
bind list = #["Recap!", "This", "list", "can", "only", "hold", "strings."]
for word in list {
  #print word
}
```

When two variables are given, the loop provides `index, value` for lists & strings, and `key, value` for maps. Use `_` to discard a variable (it cannot be read afterward).

```lua
for i, value in some_list {
  if some_list[i] is value { #print "I work!" }
}

for key, value in some_map {
  if some_map[key] is value { #print "I work!" }
}

for key, _ in some_map {
  #print key
  #print _ -- [Runtime Error]: '_' is discarded and cannot be read.
}
```

Strings are iterable:

```lua
bind name = "Mimir"

for char in name {
  #print char
}
-- Result: M, i, m, i, r

for i, char in name {
  #print "Char #|i| is #|char|"
}
```

### While & Until

```lua
while condition {
  -- executes while true
}

until condition {
  -- executes while condition is false ("Do this UNTIL [condition] is true.")
}
```

### Cycle

`cycle` is a high-level convenience tool for fixed repetition. It accepts either a literal integer or a range.

```lua
cycle 10      {} -- repeats 10 times
cycle 0..99   {} -- repeats 99 times
cycle -50     {} -- counts up to 0, repeats 50 times
cycle -10...-100 {} -- counts down from -10 to -100
```

Rules:
- When given a **negative integer**, `cycle` counts upward toward `0`.
- When given a **range**, `cycle` follows the explicit bounds and direction of that range.

### Break & Continue

`while` & `for` loops support `break` & `continue`.

```lua
for balance in accounts {
  if balance > 0 { break }    -- exits the loop
  if balance is 0 { continue } -- skips to the next iteration
}
```

---

## 8. Processes & Closures

Mimir treats processes as **first-class citizens**. They can be declared globally, assigned to variables, or stored in collections. When referencing a process without `()`, the process itself is treated as a value (data).

```lua
process add_two_numbers(a, b) {
  return a + b
}

bind add_a_and_b = process(a, b) { return a + b } -- anonymous process

bind examples_map = {
  "add_2_numbers" = add_two_numbers,  -- note: no ()
  "add_3_numbers" = process(a, b, c) {
    return a + b + c
  },
}

add_two_numbers(1, 2)
examples_map["add_2_numbers"](1, 2)
examples_map["add_3_numbers"](1, 2, 3)
```

If a process reaches its end without hitting a `return`, it implicitly returns `nil`.

### Closures

Mimir supports closures. They behave identically to closures in Nystrom's Lox — inner processes capture variables from their enclosing scope and retain access to them even after the outer process has finished execution.

```lua
process outer() {
  bind outer_variable = "Hello!"

  process inner() {
    #print outer_variable -- still accessible after outer() finishes
  }

  return inner
}

bind ps = outer()
ps() -- prints "Hello!"
```

### Toolsets

A toolset creates a **static module** for associated processes. The processes aren't "aware" of each other — there is no implicit `this` or relative scoping. Each process is logically independent but associated with its siblings by the data it is designed to handle. This remains true to Mimir's goal of data orientation.

A toolset requires a primary name and allows for **one optional alias** set via `as`. Both must be unique within the global scope. Mimir prefers `PascalCase` for toolset names.

```lua
toolset Vector as v {
  process copy(v) {
    -- logic for copying a vector
  }
  process add(a, b) {
    -- logic for adding vectors
  }
}

bind result  = Vector.copy(some_vector)
bind result2 = v.copy(some_vector)
```

**Toolsets are not first-class citizens.** They can only be aliased at creation or during `#import`. They must be declared at the **top-level scope** (zero lexical depth) — not inside processes, loops, or conditional blocks. This ensures the program's logical infrastructure remains static and globally accessible.

```lua
-- Illegal examples:
bind v_tooling = v          -- Illegal: toolsets cannot be assigned
bind v_tooling = Vector     -- Illegal

toolset Velocity as v {}    -- Illegal: 'v' is already aliased to Vector
toolset Example as e, Ex {} -- Illegal: exactly one name and at most one alias
```

---

## 9. Directives & Standard Library

### The Directive Namespace (`#`)

Mimir strictly separates **User Logic** from **Engine-Level Directives** using the `#` symbol. There are three distinct categories:

- **Keywords** (`bind`, `if`, `until`, `for`): Dictate logical flow and grammar.
- **Directives** (`#print`, `#const`, `#import`): Direct instructions to the interpreter to perform a side effect (I/O, memory locking, etc.). They start with `#` and **do not return values**.
- **System Processes** (`$str.uppercase()`): Interpreter-provided toolsets, prefixed with `$`.

**The No-Value Rule:** A directive produces a side effect but yields nothing to the language. You cannot bind a directive to a variable:

```lua
bind value = #print "Hello!" -- [Parser Error]: Directives cannot be assigned.
```

When a line starts with `#`, the directive that follows may accept a temporary helper keyword that exists only to assist it:

```lua
#import "my_process" from "my_file.mmr"
-- 'from' has no '#'. #import needs it; the interpreter knows this.
-- You do not write: #import "thing" #from "thing.mmr"
```

### Standard Library & System Toolsets

Mimir's standard library is organized into importable system toolsets, all prefixed with `$`. They are loaded with the interpreter but must be **explicitly imported** — this helps the interpreter know what it's allowed to check, keeping it efficient.

```lua
#import $str as s   -- import with alias
#import $math       -- import without alias
```

You can opt into all system toolsets at once with the universal import syntax. The tradeoff is no aliasing:

```lua
#import $
-- System toolsets are still called as: $str.length(), $list.size(), etc.
```

```lua
#print $str.reverse("!olleH") -- "Hello!"
#print s.reverse("!olleH")    -- "Hello!" (using alias)

toolset $my_toolset {} -- [Parser Error]: '$' is reserved for system toolsets.
```

---

## 10. MVP Requirements

This section defines the minimum requirements for a functional Mimir interpreter. The goal is a rudimentary but working language — something that mirrors Nystrom's most basic, functional version of JLox, adapted to Mimir's syntax. Without this, there is no project.

### Phase 1 — Scanner / Lexer
- [ ] Tokenize all keywords, identifiers, literals (integer, float, string, boolean, nil)
- [ ] Tokenize all operators (`+`, `-`, `*`, `/`, `%`, `<`, `>`, `<=`, `>=`, `is`, `isnt`, `not`, `and`, `or`, `..`, `...`, `>>`, `#|`, `|`)
- [ ] Tokenize delimiters (`{`, `}`, `[`, `]`, `(`, `)`, `:`, `,`, `=`)
- [ ] Tokenize `#` directives and `$` system toolset prefixes
- [ ] Handle single-line (`--`) and multiline (`--(...)--`) comments, including nested multiline comments
- [ ] Report scan errors with line numbers

### Phase 2 — Parser (Recursive Descent → AST)
- [ ] Parse all expression types: arithmetic, comparison, equality (`is`/`isnt`), logical (`not`/`and`/`or`), grouping, unary negation
- [ ] Parse `select`/`spare` ternary expressions
- [ ] Parse `bind` variable declarations (with and without initializer)
- [ ] Parse `#const` and `#global` modifiers
- [ ] Parse `if`/`else if`/`else` statements
- [ ] Parse `unless` statements
- [ ] Parse `while` and `until` loops
- [ ] Parse `for...in` loops (range, list, map, string)
- [ ] Parse `cycle` loops (integer and range)
- [ ] Parse `match`/`case`/`default` statements (including multi-match and `>>` capture)
- [ ] Parse `process` declarations (named and anonymous)
- [ ] Parse `return` statements
- [ ] Parse `break` and `continue`
- [ ] Parse `#print` directive
- [ ] Parse `#import` directive (system toolsets and file imports)
- [ ] Parse `toolset` declarations
- [ ] Parse list literals (including typed `#[...]` and `#type[]`)
- [ ] Parse map literals (with trailing comma support)
- [ ] Parse range literals (`..` and `...`)
- [ ] Parse index/subscript access (`list[i]`, `map["key"]`, `str[i]`, slice `list[a..b]`)
- [ ] Report parse errors with line numbers

### Phase 3 — Tree-Walk Interpreter
- [ ] Evaluate all expression types
- [ ] Implement lexical scoping (environment chain)
- [ ] Implement variable binding, assignment, and lookup
- [ ] Implement `#const` (prevent reassignment) and `#global` (hoist to global scope)
- [ ] Implement `if`/`else if`/`else`, `unless`
- [ ] Implement `while`, `until`, `for...in`, `cycle` with `break`/`continue`
- [ ] Implement `match` as desugared `if-else-if` equality checks (with `>>` capture)
- [ ] Implement process declaration, call, and `return`
- [ ] Implement closures (captured environments)
- [ ] Implement implicit `nil` return for processes
- [ ] Implement list operations: creation, index access, out-of-bounds → `nil`, typed lists
- [ ] Implement map operations: creation, key access, key assignment
- [ ] Implement range creation, iteration, and slicing
- [ ] Implement string indexing and iteration
- [ ] Implement integer → float promotion for mixed arithmetic (only implicit conversion)
- [ ] Implement `#print` directive
- [ ] Implement `$type.of()` and `$type.all()`
- [ ] Implement hard runtime errors with line numbers (crash on type mismatches, division by zero, etc.)

### Phase 4 — Minimal Standard Library
- [ ] `$type.of(n)` — returns type string
- [ ] `$type.all()` — returns list of all type strings
- [ ] `$list.push(list, val)` — appends to a list
- [ ] `$list.size(list)` — returns list length
- [ ] `$str.size(str)` — returns string length
- [ ] `$str.reverse(str)` — reverses a string

### Definition of Done

A Mimir MVP is complete when the following program runs correctly end-to-end:

```lua
process greet(name) {
  return "Hello, #|name|!"
}

bind names = ["Odin", "Thor", "Mímir"]

for name in names {
  #print greet(name)
}

bind counter = 0
while counter < 3 {
  #print counter
  counter = counter + 1
}

process make_adder(n) {
  return process(x) { return x + n }
}

bind add5 = make_adder(5)
#print add5(10) -- 15
```

---

## 11. Appendix / Future Roadmap

These are planned improvements for after the MVP is complete:

- **Bytecode VM**: Refactor the Odin backend from a tree-walk interpreter to a stack-based bytecode virtual machine. This will significantly reduce execution overhead and open the door to lower-level optimization techniques.
- **True Structural Pattern Matching**: Transition `match` from desugared `if-else-if` chains to a dedicated `Match` instruction in the VM, enabling destructuring binds and type-guarded patterns.
- **String Interpolation Optimization**: The initial `#|...|` interpolation will be implemented via desugaring. Post-MVP, this will be optimized at the VM level.
- **Expanded Standard Library**: Grow the `$str`, `$list`, `$math`, `$map`, and `$type` toolsets with a fuller set of utilities.
- **JIT**: This one's far out there, but I'd like to try adding a special directive, maybe ```#hot```, ```#jit```, etc. for processes & loops that tells the interpreter to JIT compile the code. I'd try to do this with [GNU Lightning](https://www.gnu.org/software/lightning/).


> This README.md is derived from the first one I put together in [LEGACY.md](./LEGACY.md). I told [Cline](https://cline.bot) the following: "I'm making a programming language called Mimir. It's both a BYU–Idaho senior project and a passion project. I will have about 11 weeks to reach a working MVP. I'm making it with Odin. My plan is to follow along Robert Nystrom's [jLox implementation](https://github.com/munificent/craftinginterpreters) in Crafting Interpreters and to break off when he gets into classes and OOP. Please deeply study & comprehend @/README.md _[this is the original, now LEGACY.md]_. It's my quick-shot run down of the language. Once you have a good understanding, output a new summary/specification document in @/V2.md _[now this file]_. Try to stay true to my writing style, & preserve **as much** of my original content as possible. Make it flow logically."