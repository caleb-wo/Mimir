# Mimir

At a high level, Mimir (_named after the Norse god: [Mímir](https://en.wikipedia.org/wiki/Mímir)_) is a dynamic tree-walk interpreted langauge. It features support for object-oriented paradigms & has closures. It's inspired by Lox, the language by Robert Nystrom featured in [Crafting Interpreters](https://www.craftinginterpreters.com/the-lox-language.html). 

Goals of Mimir are as follows:

1. **Learning**: As a Software Engineering student at BYU–Idaho, this senior project serves as my springboard into the deep well of programming language research, interpreter architecture, & compiler engineering.
2. **Data Oriented Syntax**: Mimir's syntax is designed to be highly expressive, directly representing the movement & transformation of data under the hood. It utilizes a fundamentally C-flavored syntax, but introduces unique differences to highlight data flow.
3. **Simple**: This language should be a small & tight language that is easy to learn & get rolling with. It's a scripting language after all. 

# Core Syntax & Grammar

## Data Types

### Booleans

Mimir contains 2 Boolean values: true & false.

### Strings

Strings are connotated with double quotes. Mimir also supports string interpolation. This will first be done through desugaring, but once MVP is hit, this process will be optomized. Strings are not objects, they are raw primitives.

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

Mimir features standard arithmetic operations. Notably, the **%** operator calculates the true Euclidean modulus rather than a simple C-style remainder (e.g., -5 % 3 evaluates to 1, not -2). When performing arithmetic on an interger or a floating point value, the interger will be promoted to float under the hood. A float is never demoted & this is the only place in the whole language where an implicit conversion will happen.

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

>> String comparison using builtin length() function.
#length(str_one) > #length(str_two) >> #process() denotes a global interpreter function
```

The equality operators "==" & "!=" can be used to test any 2 values. It can also be used to test for types.

```js
5 == 5 >> true
5 == 5.0 >> false
"Thor" != "Zeus" >> true
"Hi" == "Hi" >> true

bind value1 = ""
bind value2 = 18
#type(value1) == #type(value2) >> false
```
