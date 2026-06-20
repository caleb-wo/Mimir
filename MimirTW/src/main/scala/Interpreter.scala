package tree.walk.mimir

class Interpreter:
  def evaluate(expr: Expr): Any = expr match
    case Expr.Literal(value)         => value
    case Expr.Grouping(expression)   => evaluate(expression)
    case Expr.Unary(operator, right) => 
      val rightVal = evaluate(right)
      operator.tokenType match
        case TokenType.Minus =>
          rightVal match
            case i: Int    => -i
            case d: Double => -d
            case _         => throw new RuntimeException("Operand must be a number.")
        case TokenType.Not => !isTruthy(rightVal)
        case _ => null 
    case Expr.Binary(left, operator, right) =>
      val leftVal = evaluate(left)
      val rightVal = evaluate(right)
      operator.tokenType match
        case TokenType.Minus =>
          (leftVal, rightVal) match
            case (l: Int, r: Int)       => l - r
            case (l: Double, r: Double) => l - r
            case (l: Int, r: Double)    => l.toDouble - r
            case (l: Double, r: Int)    => l - r.toDouble
            case _                      => throw RuntimeException("Operands must be numbers.")
        case TokenType.Plus =>
          (leftVal, rightVal) match
            case (l: Int, r: Int)       => l + r
            case (l: Double, r: Double) => l + r
            case (l: Int, r: Double)    => l.toDouble + r
            case (l: Double, r: Int)    => l + r.toDouble
            case (l: String, r: String) => l + r
            case _                      => throw RuntimeException("Operands must be two numbers or two strings.")
        case TokenType.Slash =>
          (leftVal, rightVal) match
            case (l: Int, r: Int)       => l / r
            case (l: Double, r: Double) => l / r
            case (l: Int, r: Double)    => l.toDouble / r
            case (l: Double, r: Int)    => l - r.toDouble
            case _                      => throw RuntimeException("Operands must be numbers.")
        case TokenType.Star =>
          (leftVal, rightVal) match
            case (l: Int, r: Int)       => l * r
            case (l: Double, r: Double) => l * r
            case (l: Int, r: Double)    => l.toDouble * r
            case (l: Double, r: Int)    => l * r.toDouble
            case _                      => throw RuntimeException("Operands must be numbers.")
        case TokenType.Greater =>
          (leftVal, rightVal) match
            case (l: Int, r: Int)       => l > r
            case (l: Double, r: Double) => l > r
            case (l: Int, r: Double)    => l.toDouble > r
            case (l: Double, r: Int)    => l > r.toDouble
            case _                      => throw RuntimeException("Operands must be numbers.")
        case TokenType.GreaterEqual =>
          (leftVal, rightVal) match
            case (l: Int, r: Int)       => l >= r
            case (l: Double, r: Double) => l >= r
            case (l: Int, r: Double)    => l.toDouble >= r
            case (l: Double, r: Int)    => l >= r.toDouble
            case _                      => throw RuntimeException("Operands must be numbers.")
        case TokenType.Less =>
          (leftVal, rightVal) match
            case (l: Int, r: Int)       => l < r
            case (l: Double, r: Double) => l < r
            case (l: Int, r: Double)    => l.toDouble < r
            case (l: Double, r: Int)    => l < r.toDouble
            case _                      => throw RuntimeException("Operands must be numbers.")
        case TokenType.LessEqual =>
          (leftVal, rightVal) match
            case (l: Int, r: Int)       => l <= r
            case (l: Double, r: Double) => l <= r
            case (l: Int, r: Double)    => l.toDouble <= r
            case (l: Double, r: Int)    => l <= r.toDouble
            case _                      => throw RuntimeException("Operands must be numbers.")
        case TokenType.Is => isEqual(left, right)
        case TokenType.Isnt => !isEqual(left, right)
        case _ => null
  
  private def isTruthy(value: Any): Boolean =
    value match
      case null       => false
      case b: Boolean => b
      case _          => true
          
  private def isEqual(a: Any, b: Any): Boolean =
    if a == null && b == null then true
    else if a == null then false
    else a == b

//7.3
  