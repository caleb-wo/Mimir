package tree.walk.mimir

enum Expr:
  case Binary(left: Expr, operator: Token, right: Expr)
  case Grouping(expression: Expr)
  case Literal(value: Any)
  case Unary(operator: Token, right: Expr)

  def printer: String = this match
    case Binary(left, op, right) => parenthesize(op.lexeme, left, right)
    case Grouping(expr)          => parenthesize("group", expr)
    case Literal(null)           => "nil"
    case Literal(value)          => value.toString
    case Unary(op, right)        => parenthesize(op.lexeme, right)

  private def parenthesize(name: String, exprs: Expr*): String =
    val builder = StringBuilder()
    builder.append("(").append(name)
    for expr <- exprs do
      builder.append(" ").append(expr.printer)
    builder.append(")")
    builder.toString
end Expr
