import lexing_tools;
import function_parsers;
import symbol_table;
import analyze_semantics;
import std.stdio: writeln;
import structures: Program;
import executor;

void main(string[] arguments) {
    SymbolTable table = new SymbolTable;
    Lexer lexer = new Lexer(table);
    lexer.process_source(arguments);
    Program* program = parse_program(lexer, arguments[1]);
    semantic_analysis(program, table);
    auto TreeWalker = new ExecutionUnit(table, program);
    TreeWalker.execute();
    writeln("Program Successful.");
}