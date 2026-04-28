# Mimir

At a high level, Mimir (_named after the Norse god: [Mímir](https://en.wikipedia.org/wiki/Mímir)_) will be a dynamic tree-walk interpreted langauge. It'll feature support for object-oriented paradigms & has closures. It's inspired by Lox, the language by Robert Nystrom featured in [Crafting Interpreters](https://www.craftinginterpreters.com/the-lox-language.html). 

Goals of Mimir are as follows:

1. **Learning**: As a Software Engineering student at BYU–Idaho, this senior project serves as my springboard into the deep well of programming language research, interpreter architecture, & compiler engineering.
2. **Data Oriented Syntax**: Mimir's syntax is planned to be highly expressive, directly representing the movement & transformation of data under the hood. It utilizes a fundamentally C-styled syntax, but introduces unique differences to highlight data flow.
3. **Simple**: This language should be a small & tight language that is easy to learn & get rolling with. It's a scripting language after all. 

# Core Syntax & Grammar

## Data Types

### Booleans

Mimir contains 2 Boolean values: true & false.

### Strings

Strings are connotated with double quotes. Mimir is planned to support string interpolation. This will first be done through desugaring, but once MVP is hit, this process will be optomized. Strings are not objects, they are raw primitives.

```js
bind name = "Mímir"
bind greeting = 'Hello from #|name|!'
bind another_example = '#|name| is over #| 2500 * 2 | years old.'
```

### Numbers

Numbers can either be integers or floating points numbers. Numbers are not objects, they are raw primitives.

```js
bind interger = 10
bind float    = 10.10
```

### Nothing

In Mimir, "_nothing_" is represented simply:

```js
bind amount_of_cookies = nil >> 😢
```

### Arrays

Mimir will include dynamic arrays. 

```js
bind dynamic_array = ["Item 1", "Item 2", 3, 55.55]
#push(dynamic_array, "Item 3") >> #process() denotes an interpreter-provided function
```

By default, arrays can hold any type. However, for performance, & memory efficiency, you can type an array. To initialize an empty typed array, Mimir uses the "#!" prototype directive. The interpreter infers the array's type from the provided dummy value, but does not insert the value into the array.

```js
bind dyn_typed_array   = #["Value 1", "Value 2"] >> assumes string
#push(dyn_type_array, 25) >> ERROR: dyn_type_array is typed to "string" but recieved an int.

bind example2 = #!["string"] >> example2 here is empty.
bind int_example = #![1] 
bind float_example = #![1.1] >> Any dummy value can be used (e.g., 10000, 12.4325, etc.)
```

### Maps

Mimir supports dynamic key-value data structures known as Maps. Maps are declared using standard JSON-style curly braces `{}`.

To prioritize developer ergonomics and clean version control, Map declarations fully support **hanging (trailing) commas**.

Maps can also hold functions. More later in the "Processes" section.

```js
bind map = {
  "first_name": "SpongeBob",
  "age": 40,
}
map["last_name"] = "SquarePants"
#print map["first_name"] >> prints SpongeBob
```

### Comments

Mimir will support single & multiline comments & will do so with the following syntax.

```js
>> This is a single lined comment.

>(
  This is a multilined comment.
  >(
  	Comments can be nested.
	)>
)>
```

## Expressions

### Arithmetic

Mimir will feature standard arithmetic operations. Notably, the **%** operator calculates the true Euclidean modulus rather than a simple C-style remainder (e.g., -5 % 3 evaluates to 1, not -2). ❗️When performing arithmetic on an interger or a floating point value, the interger will be promoted to float under the hood for convenience. A float is never demoted for any reason & this is the only place in the whole language where an implicit conversion will happen.

```js
bind result = add + me
result = subtract - me
result = multiply * me
result = divide / me
result = modulus % me
-make_me_negative
```

### Comparison & Equality

Mimir will have standard comparison operators. All of these expressions will return a Boolean value & can only be used on numbers.

```js
less < than
less_than < or_equal
greater > than
greater_than >= orEqual

>> String comparison using builtin #length() process.
#length(str_one) > #length(str_two)
```

The equality operators "is" & "isnt" can be used to test any 2 values. It can also be used to test for types. #type() returns "boolean," "string," "number," or "nil."

```js
5 is 5 >> true
5 is 5.0 >> false
"Thor" isnt "Zeus" >> true
"Hi" is "Hi" >> true

bind value1 = ""
bind value2 = 18
#type(value1) is #type(value2) >> false, tested: "string" == "integer"
```

### Logical Operators

In Mimir, the not operator is the word 'flip.'

```js
not true >> false
not false >> true
```

The other 2 logical operators/control flow statements are "and" & "or." Both are short circuiting. 'and' returns the left value if it's false & doesn't check the next value. 'or' returns "true" if the first value is true without checking the second.

```js
true and true >> true
true and false >> false
i_am_false() and i_am_true() >> i_am_true() is never checked.

true or true >> true
false or true >> true
i_am_true() or i_am_false() >> i_am_false() is never checked.
```

# The Intrinsic Namespace (`#`)

To maximize memory safety and prevent global shadowing, Mimir strictly separates user-defined logic from engine-level commands using the `#` symbol (The Intrinsic Namespace).

Mimir draws a definitive line between **Keywords** and **System Directives**:

- **Keywords (`bind`, `if`, `and`, `not`):** These dictate the logical flow and grammar of the script. They exist in "User Space."
- **System Directives (`#print`, `#const`, `#push()`):** These are direct instructions to the underlying interpreter regarding memory allocation, I/O, or system-level evaluation. They exist in "System Space."

By keeping all standard library functions and environment modifiers behind the `#` namespace, Mimir guarantees that a user can never accidentally overwrite a core system function with a local variable.

## Statements

Statements in Mimir are prefixed with "```#```," as mentioned.

```js
#print "Hello"
```

### #statements versus #processes()

In Mimir, the difference between a statement like ```#print``` & a function like ```#push(a, b)``` might be unclear at first. However, it's not to complicated. Functions are called processes. We'll get into them later, but for now a process evaluates to a value. It takes data in, transforms it, and gives something back (even if it just gives back the updated array or a success boolean). 

```js
bind new_size = #push(my_arr, "Item") >> Legal
```

A statement does *not* evaluate to a value. It is a raw command that produces a "side effect" (like putting text on a screen with ```#print``` or locking memory with ```#const```). It yields nothing. You cannot assign it to a variable:

```js
bind value = #print "Hello, World!" >. Illegal, parser will crash.
```

## Variables

Variables are declared using the bind keyword, emphasizing the attachment of data to a reference. If a variable is declared without an initializer, it defaults to nil. Mimir also supports comma-separated multi-declarations.
```js
bind value = "Hello!"
bind value2 >> value2 is nil
bind value3, value4, value5
```

Variable declarations can be modified using system statements to alter their state or scope. It will support constant & global variables. "#const" locks the variable, preventing reassignment. It is recommended to use `SCREAMING_SNAKE_CASE` for constant naming. "#global" explicitly hoists the variable to the global environment, ensuring it can be accessed from anywhere in the script. It is recommended to prefix global variables with `G_`.

```js
#const bind FIXED_VALUE = "I will never change! You're stuck with me!"
#global bind G_global_value = "I am everywhere."
```

## Control Flow

In Mimir, you have if, unless, for, match, & while. 

### IF

```js
if condition {
  #print "yes"
} else if other_condition {
  #print "other yes"
} else {
  #print "no"
}
```

### Unless

```js
unless condition {
  #print "no"
} else unless other_condition {
  #print "other no"
} else {
  #print "yes"
}
```

### Match

The `match` statement provides a powerful, readable alternative to complex branching logic. Under the hood, the interpreter **desugars** the `match` block into an `if-else-if` chain. Here are some key features:

* **No Fallthrough:** To ensure safety and prevent bugs, Mimir cases are mutually exclusive. Once a match is found and its block is executed, the interpreter exits the statement.
* **Multi-Match:** Multiple values can be matched to a single block using a comma-separated list.

```js
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

```js
match #type(thing) {
  case "string": #print '#|thing| is a string!'
  case "integer": #print '#|thing| is an integer!'
  case "float": #print '#|thing| is a float!'
  case "boolean": #print '#|thing| is a boolean!'
  case "array": #print '#|thing| is an array!'
  case "map": #print '#|thing| is a map!'
  case "process": #print '#|thing| is a process!'
  case "nil": #print '#|thing| is nil!'
  default: #print "Something really, really weird happened."
}
```

### The Capture Operator (`#>`)

Mimir includes a specialized **redirection operator** (`#>`) to create an alias of the matched value. This provides a **scoped reference** (not a copy), allowing the developer to access the data under a specific name within the `case` block.

```js
match http_status {
  case 400, 401, 403, 404 #> error_code:
  	#print "Client failure: #|error_code|"
  default #> unknown_code:
  	>> This is legal.
}
```

