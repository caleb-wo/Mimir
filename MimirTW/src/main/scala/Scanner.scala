package tree.walk.mimir

import scala.collection.mutable.ListBuffer
import TokenType.*

class Scanner(source: String):
  private val tokens = ListBuffer[Token]()
  private var start = 0
  private var current = 0
  private var line = 1
  private val keywords = Map(
    "and" -> And
    ,"or" -> Or
    ,"not" -> Not
    ,"bind" -> Bind
    ,"if" -> If
    ,"else" -> Else
    ,"while" -> While
    ,"process" -> Process
    ,"return" -> Return
    ,"true" -> True
    ,"false" -> False
    ,"nil" -> Nil
    ,"is" -> Is
    ,"isnt" -> Isnt
  )
  
  private def isAtEnd: Boolean =
    current >= source.length

  def scanTokens(): List[Token] =
    while !isAtEnd do
      start = current
      scanToken()
    tokens += Token(EOF, "", null, line)
    tokens.toList
  
  private def addToken(tokenType: TokenType, literal: Any = null): Unit =
    val text = source.substring(start, current)
    tokens += Token(tokenType, text, literal, line)

  private def scanToken(): Unit =
    val c = advance()
    
    c match
      // Single character lexemes
      case '(' => addToken(LeftParen)
      case ')' => addToken(RightParen)
      case '{' => addToken(LeftBrace)
      case '}' => addToken(RightBrace)
      case ',' => addToken(Comma)
      case '+' => addToken(Plus)
      case '*' => addToken(Star)
      case '/' => addToken(Slash)
      case '#' => addToken(Hash)
      case '=' => addToken(Equal)
      // Two char lexemes
      case '<' => addToken(if matchChar('=') then LessEqual else Less)
      case '>' => addToken(if matchChar('=') then GreaterEqual else Greater)
      case '-' => 
        if matchChar('-') then
          while peek() != '\n' && !isAtEnd do advance()
        else
          addToken(Minus)
      // Whitespace and new lines
      case ' ' | '\r' | '\t' => ()
      case '\n' => line += 1
      // Literals
      case '"' => string()
      case c if isDigit(c) => number()
      case c if isAlpha(c) => identifier()

      case  _  => error(line, s"Unexpected character: '$c'.")
  
  private def advance(): Char =
    val c = source.charAt(current)
    current += 1
    c

  private def matchChar(expected: Char): Boolean =
    if isAtEnd || source.charAt(current) != expected then
      false
    else 
      current += 1
      true

  private def peek(): Char =
    if isAtEnd then '\u0000' else source.charAt(current)
  
  private def peekNext(): Char =
    if current + 1 >= source.length then '\u0000'
    else source.charAt(current + 1)
  
  private def isDigit(c: Char): Boolean =
    c >= '0' && c <= '9'
    
  private def isAlpha(c: Char): Boolean =
    (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    c == '_'

  private def isAlphaNumeric(c: Char): Boolean =
    isAlpha(c) || isDigit(c)

  private def string(): Unit =
    while peek() != '"' && !isAtEnd do
      if peek() == '\n' then line += 1
      advance()
    
    if isAtEnd then
      return error(line, "Unterminated string.")
    
    advance()

    val value = source.substring(start + 1, current - 1)
    addToken(String, value)
  
  private def number(): Unit =
    while isDigit(peek()) do advance()

    var isFloat = false

    if peek() == '.' && isDigit(peekNext()) then
      isFloat = true
      advance()
      while isDigit(peek()) do advance()

    val value = source.substring(start, current)

    if isFloat then
      addToken(Float, value.toDouble)
    else 
      addToken(Integer, value.toInt)

  private def identifier(): Unit =
    while isAlphaNumeric(peek()) do advance()

    val text = source.substring(start, current)
    val tokenType = keywords.getOrElse(text, TokenType.Identifier)
    addToken(tokenType)
