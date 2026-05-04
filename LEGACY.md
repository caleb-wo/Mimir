# Mimir

<sub>(If Mimir is being <em><strong>seriously</strong></em> used somewhere, please let me know & I'll get back to workshopping.)</sub>

At a high level, Mimir (_named after the Norse god: [Mímir](https://en.wikipedia.org/wiki/Mímir)_) will be a dynamic tree-walk interpreted langauge. I understand tree-walking is not performant. This is to meet the immediate requirements of my senior project. Following the MVP, I plan to refactor the Odin backend into a stack-based bytecode virtual machine to significantly reduce execution overhead and explore lower-level optimization techniques.

It'll feature support for lexical closures & first-class citizen ship for processes (functions). I developed it by applying what I learned from Lox, the language by Robert Nystrom featured in [Crafting Interpreters](https://www.craftinginterpreters.com/the-lox-language.html). It will not have support for object-oriented programming. In Mimir, data & logic are separate.

Goals of Mimir are as follows:

1. **Learning**: As a Software Engineering student at BYU–Idaho, this senior project serves as my springboard into the deep well of programming language research, interpreter architecture, & compiler engineering, things I've been intrigued by for a long time.
2. **Data Oriented Syntax**: Mimir's syntax is planned to be honest, directly representing the movement & transformation of data under the hood to the best I can. It utilizes a fundamentally C-styled syntax, but introduces unique differences to highlight data flow. It also favors conversational operators (is, isnt, not, and, or) to improve scripting ergonomics.
3. **Simple**: This language should be a small & tight enough language that is easy to learn & get rolling with. It's a scripting language after all. 

# Core Syntax & Grammar

## Data Types

Mimir has 10 total types that it uses under the hood. This is a dynamic language, but accessing type information is useful & powerful.  ```$type.of(n)``` returns a string representation for the type of ```n```. ```$type.all()``` returns a list of every type in the language: ```["string", "integer", "float", "boolean", "list", "map", "range", "process", "toolset", "nil"]```

There are many tools for working with types in the ```$type``` system toolset. You'll read about toolsets in the section on processes (functions).

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

Numbers can either be integers or floating point numbers. Numbers are not objects, they are raw primitives. Mimir does differentiate between integers & floats.

```lua
bind interger = 10
bind float    = 10.10
```

### Nothing

In Mimir, "_nothing_" is represented simply:

```lua
bind amount_of_cookies = nil -- 😢
```

### Lists

Mimir will include dynamic lists or arrays. Accessing outside of a list's boundary returns ```nil```.

```lua
bind list = ["Item 1", "Item 2", 3, 55.55]
(list[0] is "Item 1") -- Evaluates to true
(list[100] is nil) -- Evaluates to true

$list.push(list, "Item 3") 
-- $code.process() denotes an interpreter-provided toolset function... more on this later
```

By default, lists can hold any type. However, for performance, & memory efficiency, you can type a list. 

```lua
bind typed_list = #["Value 1", "Value 2"] -- assumes string
$list.push(dyn_type_list, 25) -- ERROR: dyn_type_list is typed to "string" but recieved an int.
```

To create an empty list with a strict type lock, use the `#` directive followed by a **type statement** and empty brackets. This instructs the interpreter to enforce type safety for all future operations on that list without populating it with initial data.

```lua
bind example2 = #string[] -- example2 here is empty.
bind int_example = #integer[] 
bind float_example = #float[] 
```

### Maps

Mimir supports dynamic key-val

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
for idx,_ in my_list {} -- Preferred
for idx in 0..$list.size(list) {} -- Non-idiomatic/pointless
```

Ranges can be treated as values & you can have reverse ranges & negatives. 

```lua
bind my_range = 0..100
my_range = 50..0 -- Counts down from 50 to 1
bind last_nights_weather_range = -10...17 -- Counts from -10 to 17

for i in my_range {} -- Legal
```

If you just need to do something 'x' amount of times, there is a special ```cycle``` loop available to you. This treats the range **or** number as a count.

```lua
cycle 1...100 {} -- Just does something 100 times.
cycle 100 {} -- exact same thing. Just repeats 100 times.
```

Ranges can also be used to take slices of a list or string. 

```lua
bind list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,]

bind example1 = list[2..5] -- equals [3, 4, 5], 6 at position 5 is exluded
bind example2 = list[2...5] -- equals [3, 4, 5, 6], 6 at position 5 is included
```

Of course, they can be passed to processes:

```lua
bind entity_range = 1...calculate_enemy_count(GAME_DIFFICULTY_SETTING) 
process spawn_enemies(entity_range){
  cycle entity_range {
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
greater_than >= or_equal

$str.size(str_one) > $str.size(str_two)
```

The equality operators ```is``` & ```isnt``` can be used to test any 2 values. They are commonly represented by ```==``` & ```!=``` in other languages.

 They can also be used to test for types. Review: ```$type.of(n)``` returns a string representation of ```n```. Mimir has 10 types: ```"string", "integer", "float", "boolean", "list", "map", "range", "process", "toolset", "nil"```

```lua
5 is 5 -- true
5 is 5.0 -- false
"Thor" isnt "Zeus" -- true
"Hi" is "Hi" -- true

bind value1 = ""
bind value2 = 18
$type.of(value1) is $type.of(value2) -- false, tested: "string" == "integer"
```

### Logical Operators

In Mimir, the not operator is the word ```not```.

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

### Select / Spare

`select / spare` is a **ternary expression**. This means it is legal anywhere a value is expected, provided it is wrapped in parentheses when combined with other math to avoid ambiguity, anywhere else, parentheses are optional or given (like in process calls). Because `select / spare` is an expression (it resolves to a single value), it can be used in:

- **Assignments:** `bind x = condition select 10 spare 5 -- 10 if condition is true, 5 otherwise`
- **Math Operations:** `5 + (cond select 10 spare 0)`
- **Function/Process Arguments:** `saveStatus(select "Success" spare "Error")`
- **Return Values:** `process get_status() { return active select 1 spare 0 }`
- **list/Map Initializers:** `bind scores = [100, has_bonus select 50 spare 10, 0]`

### **The Directive Namespace**

To maximize clarity, Mimir strictly separates **User Logic** from **Engine-Level Directives** using the `#` symbol.

Mimir draws a line between **Keywords**, **Directives**, and **Functions**:

- **Keywords** (`bind`, `if`, `until`, `for`): These dictate the logical flow and grammar of the script.
- **Directives** (`#print`, `#const`, ```#import```): These are direct instructions to the interpreter to perform a "side effect," such as I/O or memory locking. They start with `#` and do not return values. 
- **Processes** (```$str.uppercase()```: Mimir's interpreter comes packed with toolsets for the user. System toolsets are prefixed with '```$```'. Users cannot use '```$```' in indentifiers. System toolsets must be explicitly imported.

### **Directives (Statements)**

Directives in Mimir are prefixed with `#`. They are "Commands" that tell the engine to do something specific. Because they are actions and not values, they cannot be assigned to variables. It's a way to reach inside the interpreter.

```lua
#print "Hello, World!"
```

**The "No-Value" Rule:** A directive produces a "side effect" (like putting text on a screen) but yields nothing to the language. You cannot bind a directive to a variable:

```lua
bind value = #print "Hello!" -- Illegal: Parser Error.
```

If a line starts with ```#```, it means the immediate directive aftwards comes with a temporary keyword which exists only to assist the directive. This is the best example, & only place so far in this language that this is use:

```lua
#import "my_process" from "my_file.mmr" -- Notice that 'from' has no "#". #import needs from, the interpreter           															-- knows this, which is why you do not need to say #import "thing"  
																				-- #from "thing.mmr".
```



### **Standard Library & System Processes**

As mentioned, Mimir organizes its standard library into toolsets for the user (see bellow). These must be imported. They are all loaded with the interpreter, but explicit imports help the interpreter know what it is allowed to check, making it more efficient. All interpreter toolsets are prefixed with ```$```, this is unique to system toolsets. They can be used as follows:

```lua
#import $str, s -- Here, 's' becomes a user defined alias
#import $ -- This tells Mimir to make all std libraries available to the program. If this is done
					-- system toolsets still need to be called like so: $str.length(), $arr.length(), etc.

#print $str.reverse("!olleH") -- Prints "Hello!"
#print s.reverse("!olleH") -- Prints "Hello!"

toolset $my_toolset {} -- Illegel: '$' is reserved for system toolsets
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

Because the ```$type.of()``` system process just returns a string, you can match for a type.

```lua
match $type.of(thing) {
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
  	#print 'Unknown: #| $type.of(unknown_code) |'-- This is legal.
}
```

### For

Mimir has ```for...in``` loops. When paired with the #range() system process, it's easy to do classic ranged looping.

```lua
for i in #range(0, 100) { -- #range() is exclusive. So, this will count from 0 to 99, EXCLUDING 100.
  -- Code here
}

-- The following is also perfectly fine.
bind list = #["Recap!", "This", "list", "can", "only", "hold", "strings."]
for word in list {
  #print word
}

for i in #range(0, #size(list)) {
  -- This works as well.
}
```

When two values are followed by ```for```, the loop is given ```index, value``` for lists & ```key, value``` for maps. When needed, you can use ```_``` to ignore a variable.

```lua
for i, value in some_list {
  if some_list[i] is value { #print "I work!" }
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

In Mimir, there is a special way to associate processes. This can be done by making a 🧰toolset. A toolset creates a __static module__ for various processes. The processes aren't "aware" of each other (no implicit `this` or relative scoping). This remains true to Mimir's goal of data orientation. Each process is logically independent but remains associated with its siblings by the data it is designed to handle. A toolset requires a primary name and allows for one optional alias set via ```as```. Both must be unique within the global scope. Mimir prefers ```PascalCase``` for toolset names.

Toolsets are not first class citizens. For examples, you can **only** alias a toolset during creation or ```#import```. Toolsets must be declared at the top-level scope (zero lexical depth). They cannot be nested within processes, loops, or conditional blocks. This ensures that the program’s logical infrastructure remains static and globally accessible.

```lua
toolset Vector as v {
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
toolset Vector as v {}

bind v_tooling = v -- Illegal
bind v_tooling = Vector -- Illegal

toolset Velocity as v {} -- Illegal, naming collision with vector's 'v' alias.
toolset Example as e, Ex, exmpl {} -- Illegal: you are allowed exactly one required name and a maximum of one optional alias.
```

As mentioned prior, Mimir has a standard library organize into importable toolsets. Here's a full recap:

- System toolsets are prefixed with "$" & must be explicitly imported. Sysem toolsets require no ```from``` statement.

```lua
#import $str as s 
#import $math
```

- Users can also opt into all of them with a specialized universal import syntax:

```lua
#import $ -- The tradeoff is no aliasing
```

