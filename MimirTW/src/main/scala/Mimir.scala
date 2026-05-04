package tree.walk.mimir

import scala.io.{Source, StdIn}
import java.nio.file.{Files, Paths}
import java.nio.charset.Charset

var hadError = false

@main
def mimir(args: String*): Unit =
  if args.length > 1 then
    println("Usage: mimir [script.mmr]")
    sys.exit(64)
  else if args.length == 1 then
    runFile(args(0))
  else
    runPrompt()

def runFile(path: String): Unit =
  val source = Source.fromFile(path).mkString
  run(source)
  if hadError then sys.exit(65)

def runPrompt(): Unit =
  while true do
    print("#> ")
    val line = StdIn.readLine()
    if line == null then return
    run(line)
    hadError = false
    
def run(source: String): Unit =
  val scanner = Scanner(source)
  val tokens = scanner.scanTokens()
  
  for token <- tokens do
    println(token)

def error(line: Int, message: String): Unit =
  report(line, "", message)
  
def report(line: Int
           ,where: String
           ,message: String): Unit =
  System.err.println(s"[Line: $line] Error$where: $message")