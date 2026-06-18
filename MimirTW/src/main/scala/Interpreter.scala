package tree.walk.mimir

class Interpreter:
  def evaluate(expr: Expr): Any = expr match
    case Expr.Literal(value)       => value
    case Expr.Grouping(expression) => evaluate(expression)
    case Expr.Unary(operator, right) =>
      val rightVal = evaluate(right)
      operator.tokenType match
        case TokenType.Minus =>
          rightVal match
            case i: Int    => -i
            case d: Double => -d
            case _         => throw new RuntimeException("Operand must be a number.")
        case _ => null //7.2.3
          
      

  