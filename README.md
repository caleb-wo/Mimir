# Mimir

<sub>(If Mimir is being <em><strong>seriously</strong></em> used somewhere, please let me know & I'll get back to workshopping.)</sub>

At a high level, Mimir (_named after the Norse god: [Mímir](https://en.wikipedia.org/wiki/Mímir)_) will be a dynamic tree-walk interpreted langauge. I understand tree-walking is not performant. This is to meet the immediate requirements of my senior project. Following the MVP, I plan to refactor the Odin backend into a stack-based bytecode virtual machine to significantly reduce execution overhead and explore lower-level optimization techniques.

It'll feature support for lexical closures & first-class citizen ship for processes (functions). I developed it by applying what I learned from Lox, the language by Robert Nystrom featured in [Crafting Interpreters](https://www.craftinginterpreters.com/the-lox-language.html). It will not have support for object-oriented programming. In Mimir, data & logic are separate.

Goals of Mimir are as follows:

1. **Learning**: As a Software Engineering student at BYU–Idaho, this senior project serves as my springboard into the deep well of programming language research, interpreter architecture, & compiler engineering, things I've been intrigued by for a long time.
2. **Data Oriented Syntax**: Mimir's syntax is planned to be honest, directly representing the movement & transformation of data under the hood to the best I can. It utilizes a fundamentally C-styled syntax, but introduces unique differences to highlight data flow. It also favors conversational operators (is, isnt, not, and, or) to improve scripting ergonomics.
3. **Simple**: This language should be a small & tight language that is easy to learn & get rolling with. It's a scripting language after all. 

# Core Syntax & Grammar

## Data Types

### Booleans

Mimir contains 2 Boolean values: ```true``` & ```false```.

### Strings

Strings are connotated with double quotes. Mimir is planned to support string interpolation. This will first be done through desugaring, but once MVP is hit, this process will be optomized. Strings are not objects, they are raw primitives.

```lua
bind name = "Mímir"
bind greeting = 'Hello from #|name|!'
bind greeting2 = "Hello from " + name + "!"
bind another_example = '#|name| is over #| 2500 * 2 | years old.'

name[0] is "M"
```

### Numbers

Numbers can either be integers or floating points numbers. Numbers are not objects, they are raw primitives.

```lua
bind interger = 10
bind float    = 10.10
```

### Nothing

In Mimir, "_nothing_" is represented simply:

```lua
bind amount_of_cookies = nil -- 😢
```

### Arrays

Mimir will include dynamic arrays. 

```lua
bind dynamic_array = ["Item 1", "Item 2", 3, 55.55]
#push(dynamic_array, "Item 3") -- #process() denotes an interpreter-provided function
```

By default, arrays can hold any type. However, for performance, & memory efficiency, you can type an array. 

```lua
bind dyn_typed_array   = #["Value 1", "Value 2"] -- assumes string
#push(dyn_type_array, 25) -- ERROR: dyn_type_array is typed to "string" but recieved an int.
```

To initialize an empty typed array, Mimir uses the "#!" prototype directive. The interpreter infers the array's type from the provided dummy value, but does not insert the value into the array.

```lua
bind example2 = #!["string"] -- example2 here is empty.
bind int_example = #![1] 
bind float_example = #![1.1] -- Any dummy value can be used (e.g., 10000, 12.4325, etc.)
```



### Maps

Mimir supports dynamic key-value data structures known as Maps. Maps are declared using standard JSON-style curly braces `{}`.

To prioritize developer ergonomics and clean version control, Map declarations fully support **trailing/hanging commas**.

Maps can also hold functions. More later in the "Processes" section. Mimir doesn't support dot access, except for ```toolset``` which you'll read about later.

```lua
bind map = {
  "first_name": "SpongeBob",
  "age": 40,
}
map["last_name"] = "SquarePants"
map["age"] = 39 -- was 40

#print map["first_name"] -- prints SpongeBob
```

### Range

Mimir will have support for a range data type.  (you'll see some sneek peaks for loops, match cases, functions, & more here)

```lua
for i in 0..10  {} -- Counts from 0 to 9, 10 is excluded
for i in 0...10 {} -- Count from 0 to 10, 10 is included
match (grade) {
  case 90...100: -- checks to see if value is within range. 
  	#print "A" 
  -- etc.
}
```

The range operator `...`/```..``` requires two integer values. These can be literal numbers, variable bindings, or process results. However, for iterating over collections, use the native `for key_or_index, val in collection` syntax for better performance and readability.

```lua
for idx,_ in my_array {} -- Preferred
for idx in 0..#size(array) {} -- Non-idiomatic/pointless
```

Ranges can be treated as values & you can have reverse ranges & negatives. 

```lua
bind my_range = 0..100
my_range = 50..0 -- Counts down from 50 to 1
bind last_nights_weather_range = -10...17 -- Counts from -10 to 17

for i in my_range{} -- Legal
```

If you just need to do something 'x' amount of times, there is a special ```cycle``` loop available to you. This treats the range **or** number as a count.

```lua
cycle 1...100 {} -- Just does something 100 times.
cycle 100 {} -- exact same thing. Just repeats 100 times.
```

Ranges can also be used to take slices of an array or string. 

```lua
bind array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,]

bind example1 = array[2..5] -- equals [3, 4, 5], 6 at position 5 is exluded
bind example2 = array[2...5] -- equals [3, 4, 5, 6], 6 at position 5 is included
```

Of course, they can be passed to processes:

```lua
bind entity_range = 1...calculate_entity_space(GAME_DIFFICULTY_SETTING) 
process spawn_enemies(entity_range){
  for entity_range {
    -- work
  }
}
```

Counts will always flow from left to right:

```lua
0..50 -- counts up
50..0 -- counts down

-4..-100 -- counts down
-100..-4 -- counts up
```

### Comments

Mimir will support single & multiline comments & will do so with the following syntax.

```clojure
-- This is a single lined comment.

--(
  This is a multilined comment.
  --(
  	Comments can be nested.
	)--
)--
```

## Expressions

### Arithmetic

Mimir will feature standard arithmetic operations. Notably, the **%** operator calculates the true Euclidean modulus rather than a simple C-style remainder (e.g., -5 % 3 evaluates to 1, not -2). 

```lua
bind result = add + me
result = subtract - me
result = multiply * me
result = divide / me
result = modulus % me
-make_me_negative
```

<em>❗️When performing arithmetic on an interger or a floating point value, the interger will be promoted to float under the hood for convenience. A float is never demoted for any reason & this is the only place in the whole language where an implicit conversion will happen.</em>

### Comparison & Equality

Mimir will have standard comparison operators. All of these expressions will return a Boolean value & can only be used on numbers.

```lua
less < than
less_than < or_equal
greater > than
greater_than >= orEqual

-- String comparison using builtin #size() process. #size() also works with arrays and maps
#size(str_one) > #size(str_two)
```

The equality operators ```is``` & ```isnt``` can be used to test any 2 values. They can also be used to test for types. ```#type()``` returns a string representation for every type in the language: ```"string", "integer", "float", "boolean", "array", "map", "range", "process", "toolset", "nil"```

```lua
5 is 5 -- true
5 is 5.0 -- false
"Thor" isnt "Zeus" -- true
"Hi" is "Hi" -- true

bind value1 = ""
bind value2 = 18
#type(value1) is #type(value2) -- false, tested: "string" == "integer"
```

### Logical Operators

In Mimir, the not operator is the word 'flip.'

```lua
not true -- false
not false -- true
```

The other 2 logical operators/control flow statements are ```and``` & ```or```. Both are short circuiting. ```and``` returns the left value if it's ```false``` & doesn't check the next value. ```or``` returns ```true``` if the first value is true without checking the second.

```lua
true and true -- true
true and false -- false
i_am_false() and i_am_true() -- SHORTCIRCUIT: i_am_true() is never checked.

true or true -- true
false or true -- true
i_am_true() or i_am_false() -- SHORTCIRCUIT: i_am_false() is never checked.
```

# The Intrinsic Namespace (`#`)

To maximize memory safety and prevent global shadowing, Mimir strictly separates user-defined logic from engine-level commands using the `#` symbol (The Intrinsic Namespace).

Mimir draws a line between **Keywords** and **System Directives**:

- **Keywords (`bind`, `if`, `and`, `not`):** These dictate the logical flow and grammar of the script. They exist in "User Space."
- **System Directives (`#print`, `#const`, `#push()`):** These are direct instructions to the underlying interpreter regarding memory allocation, I/O, or system-level evaluation. They exist in "System Space."

By keeping all standard library functions and environment modifiers behind the `#` namespace, Mimir guarantees that a user can never accidentally overwrite a core system function with a local variable.

## Statements

Statements in Mimir are prefixed with "```#```," as mentioned.

```lua
#print "Hello"
```

### #statements versus #processes()

In Mimir, the difference between a statement like ```#print``` & a function like ```#push(a, b)``` might be unclear at first. However, it's not to complicated. Functions are called processes. We'll get into them later, but for now a process evaluates to a value. It takes data in, transforms it, and gives something back (even if it just gives back the updated array or a success boolean). 

```lua
bind new_size = #push(my_arr, "Item") -- Legal
```

A statement does *not* evaluate to a value. It is a raw command that produces a "side effect" (like putting text on a screen with ```#print``` or locking memory with ```#const```). It yields nothing. You cannot assign it to a variable:

```lua
bind value = #print "Hello, World!" -- Illegal, parser will crash.
```

## Variables

Variables are declared using the bind keyword, emphasizing the attachment of data to a reference. If a variable is declared without an initializer, it defaults to nil. Mimir also supports comma-separated multi-declarations.
```lua
bind value = "Hello!"
bind value2 -- value2 is nil
bind value3, value4, value5
```

Variable declarations can be modified using system statements to alter their state or scope. It will support constant & global variables. "#const" locks the variable, preventing reassignment. It is recommended to use `SCREAMING_SNAKE_CASE` for constant naming. "#global" explicitly hoists the variable to the global environment, ensuring it can be accessed from anywhere in the script. It is recommended to prefix global variables with `G_`.

```lua
#const bind FIXED_VALUE = "I will never change! You're stuck with me!"
#global bind G_global_value = "I am everywhere."
```

## Control Flow

In Mimir, you have ```if```, ```unless```, ```for```, ```match```, ```while```, ```until```, & ```cycle```. 

### IF

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

```unless``` is best used for quick negative guards, it is restricted to one branch.

```lua
unless condition {
  #print "no"
}
```

### Match

The `match` statement provides a powerful, readable alternative to complex branching logic. Currently, the `match` statement is implemented as syntactic sugar for `if-else-if` chains based on value equality. In future iterations, I plan to transition to **True Structural Pattern Matching**. This will involve moving away from desugaring to a dedicated `Match` instruction in the bytecode VM, enabling complex features like **destructuring binds** and **type-guarded patterns**. Here are some key features for the first version of ```match```:

* **No Fallthrough:** To ensure safety and prevent bugs, Mimir cases are mutually exclusive. Once a match is found and its block is executed, the interpreter exits the statement.
* **Multi-Match:** Multiple values can be matched to a single block using a comma-separated list.

```lua
match condition {
  case 200:
  	#print "Success"
  case 400, 404:
  	#print "Client Error."
  case 500:
  	#print "Server Error."
  default:
		#print "Uknown Status"
}
```

Because the ```#type()``` system process just returns a string, you can match for a type.

```lua
match #type(thing) {
  case "string": #print '#|thing| is a string!'
  case "integer": #print '#|thing| is an integer!'
  case "float": #print '#|thing| is a float!'
  -- and so on...
}
```

### The Capture Operator (`>>`)

Mimir includes a specialized **redirection operator** (`>>`) to create an alias of the matched value. This provides a **scoped reference** (not a copy), allowing access to the data under a specific name within the `case` block.

```lua
match http_status {
  case 400, 401, 403, 404 >> error_code:
  	#print "Client failure: #|error_code|"
  default >> unknown_code:
  	#print 'Unknown: #| #type(unknown_code) |'-- This is legal.
}
```

### For

Mimir has ```for...in``` loops. When paired with the #range() system process, it's easy to do classic ranged looping.

```lua
for i in #range(0, 100) { -- #range() is exclusive. So, this will count from 0 to 99, EXCLUDING 100.
  -- Code here
}

-- The following is also perfectly fine.
bind array = #["Recap!", "This", "array", "can", "only", "hold", "strings."]
for word in array {
  #print word
}

for i in #range(0, #size(array)) {
  -- This works as well.
}
```

When two values are followed by ```for```, the loop is given ```index, value``` for arrays & ```key, value``` for maps. When needed, you can use ```_``` to ignore a variable.

```lua
for i, value in some_array {
  if some_array[i] is value { #print "I work!" }
}

for key, value in some_map {
  if some_map[key] is value { #print "I work!" }
}
    
for key,_ in some_map {
  #print key
  #print _ -- ERROR, '_' is discarded
}
```

Strings are also supported.

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

Mimir's also supports special range syntax.

```lua
for i in 0..100 {} -- Counts from 0 to 99, 100 is excluded.
for i in 0...100 {} -- Counts from 0 to 100, 100 is included.
for i in 100..0 {} -- Reverse range.
for i in 100..-0 {} -- ERROR: cannot use negatives (on either side of '..')
```

### While

```lua
while condition {
  -- executes while true
}
until condition {
  -- executes while condition is false, a.k.a "Do this UNTIL [this] is true."
}
```

### More on Loops

In Mimir, ```while``` & ```for``` loops will have access to ```break``` & ```continue```.

```lua
for balance in accounts {
  if balance > 0 { break } -- for-loop is exited
  if balance is 0 { continue } -- skips to the next loop
}
```

### Cycle

You saw the cycle loop earlier. The `cycle` statement is a high-level convenience tool for fixed repetition. It accepts either a **literal integer** or a **range**. 

```lua
cycle 10 {} -- repeats code 10 times
cycle 0..99 {} -- repeats code 99 times
```

- When given a negative number, ```cycle``` will always count towards ```0```. 

- When passed a single integer, `cycle` runs that many times. If the number is negative, Mimir counts upward toward zero. 

- When passed a range, `cycle` follows the explicit bounds and direction of that range. 

```lua
cycle -50 {} -- Does some thing 50 times, counting up to 0

cycle -10...-100 {} -- Legal, counts down from -10 to -100
```

## Processes <sub>(functions)</sub>

Mimir treats processes as first-class citizens. They can be declared globally, assigned to variables, or stored in collections. When referencing a process without `()`, the process itself is treated as data.

```lua
process add_two_numbers(a, b){
  return a + b
}

bind add_a_and_b = process(a, b){ return a + b } -- Legal.

bind examples_map = {
  "add_2_numbers" = add_two_numbers, -- note the omitted ()
  "add_3_numbers" = process(a, b, c) {
    return a+b+c
  },
}
add_two_numbers(1, 2)
examples_map["add_2_numbers"](1, 2)
examples_map["add_3_numbers"](1, 2, 3)
```

If a process reaches it's end & does not ever reach a ```return``` keword, it will implicitly return ```nil```.

### Closures

Just like in Nystrom's Lox, Mimir will support closures. I encourage you to read [🖥️HERE](https://craftinginterpreters.com/the-lox-language.html#closures) as they will act the same exact way.

```lua
process outer(){
  bind outer_variable = "Hello!"
  
  process inner(){
    #print outer_variable -- inner() will know outer_variable even after outer() has finished execution                             -- and its scope would normally be destroyed.
  }
  
  return inner
}

bind ps = outer()
ps() -- prints "Hello!"
```

Mimir supports variable shadowing, allowing inner scopes to declare variables with the same name as those in outer scopes without affecting the original value. When a name is referenced, the interpreter resolves it by searching from the innermost scope outward, ensuring that local logic remains isolated from global state.

```lua
process outer(){
  bind a = "Hello!"
  process inner(){
    bind a = "Hola!"
    #print a
  }
}

bind ps = outer()
ps() -- prints "Hola!"
```

### Toolsets

In Mimir, there is a special way to associate processes. This can be done by making a 🧰toolset. A toolset creates a __static module__ for various processes. The processes aren't "aware" of each other (no implicit `this` or relative scoping). This remains true to Mimir's goal of data orientation. Each process is logically independent but remains associated with its siblings by the data it is designed to handle. A toolset requires a primary name and allows for one optional alias. Both must be unique within the global scope. Mimir prefers ```PascalCase``` for toolset names. Toolsets must be declared at the top-level scope (zero lexical depth). They cannot be nested within processes, loops, or conditional blocks. This ensures that the program’s logical infrastructure remains static and globally accessible.

```lua
toolset Vector, v {
  process copy(v) {
    -- logic for copying a vector
  }
  process add(a, b){
    --logic for adding a vector
  }
  -- ...
}

bind result  = Vector.copy(some_vector)
bind result2 = v.copy(some_vector)
```

Examples of illegal code:

```lua
toolset Vector, v {}
toolset Velocity, v {} -- Illegal, naming collision with vector's 'v' alias.
toolset Example, e, Ex, exmpl {} -- Illegal: you are allowed exactly one required name and a maximum of one optional alias.
```

