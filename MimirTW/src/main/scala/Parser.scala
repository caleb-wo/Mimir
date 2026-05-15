package tree.walk.mimir

import TokenType.*
import Expr.*
import scala.compiletime.ops.double

class Parser(tokens: List[Token]):
  private var current = 0

  private def expression(): Expr =
    equality()

  private def equality(): Expr =
    var expr = comparison()

    while matchTokens(Isnt, Is) do
      val operator = previous()
      val right = comparison()
      expr = Expr.Binary(expr, operator, right)
    end while

    expr
  
  private def matchTokens(types: TokenType*): Boolean =
    for typeToken <- types do
      if check(typeToken) then
        advance()
        return true
    
    false

  private def check(tokenType: TokenType): Boolean =
    if isAtEnd() then false
    else peek().tokenType == tokenType

  private def advance(): Token =
    if !isAtEnd() then current += 1
    previous()
  
  private def isAtEnd(): Boolean =
    peek().tokenType == EOF
  
  private def peek(): Token =
    tokens(current)
  
  private def previous(): Token =
    tokens(current - 1)

  private def comparison(): Expr =
    var expr = term()

    while matchTokens(Greater, GreaterEqual, Less, LessEqual) do
      val operator = previous()
      val right = term()
      expr = Expr.Binary(expr, operator, right)
    end while

    expr
  
  private def term(): Expr =
    var expr = factor()

    while matchTokens(Minus, Plus) do
      val operator = previous()
      val right = factor()
      expr = Expr.Binary(expr, operator, right)
    end while

    expr

  private def factor(): Expr =
    var expr = unary()

    while matchTokens(Slash, Star) do
      val operator = previous()
      val right = unary()
      expr = Expr.Binary(expr, operator, right)
    end while

    expr

  private def unary(): Expr =
    if matchTokens(Not, Minus) then
      val operator = previous()
      val right = unary()
      Expr.Unary(operator, right)
    else
      primary()
    end if


  private def primary(): Expr =
    if      matchTokens(False) then Expr.Literal(false)
    else if matchTokens(True) then Expr.Literal(true)
    else if matchTokens(Nil) then Expr.Literal(null)
    else if matchTokens(Integer, Float, String) then 
      Expr.Literal(previous().literal)
    else if matchTokens(LeftParen) then
      val expr = expression()
      consume(RightParen, "Expect ')' after expression.")
      Expr.Grouping(expr)
    else
      throw new RuntimeException("Expect expression.")
