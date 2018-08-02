import lexing_tools;
import function_parsers;
import symbol_table;
import analyze_semantics;
import std.stdio: writeln;
import structures: Program;

void main(string[] arguments) {
    auto table = new SymbolTable;
    auto lexer = new Lexer(table);
    lexer.process_source(arguments);
    Program* program = parse_program(lexer, arguments[1]);
    semantic_analysis(program, table);
    writeln("Compilation Successful");
}