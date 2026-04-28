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
dynamic_array[?] = "Item 3" >> OR #push(dynamic_array, "Item 3")
```

By default, arrays can hold any type. However, for performance, & memory efficiency, you can type an array. To initialize an empty typed array, Mimir uses the "#!" prototype directive. The interpreter infers the array's type from the provided dummy value, but does not insert the value into the buffer.

```js
bind dyn_typed_array   = #["Value 1", "Value 2"] >> assumes string
#push(dyn_type_array, 25) >> ERROR: dyn_type_array is typed to "string" but recieved an int.

bind example2 = #!["string"] >> example2 here is empty.
bind int_example = #![1] 
bind float_example = #![1.1] >> Any dummy value can be used (e.g., 10000, 12.4325, etc.)
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
#length(str_one) > #length(str_two) >> #process() denotes an interpreter-provided function
```

The equality operators "==" & "!=" can be used to test any 2 values. It can also be used to test for types. #type() returns "boolean," "string," "number," or "nil."

```js
5 == 5 >> true
5 == 5.0 >> false
"Thor" != "Zeus" >> true
"Hi" == "Hi" >> true

bind value1 = ""
bind value2 = 18
#type(value1) == #type(value2) >> false
```
