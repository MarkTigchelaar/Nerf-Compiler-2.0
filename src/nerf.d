import lexing_tools;
import function_parsers;
import symbol_table;
import analyze_semantics;
import std.stdio: writeln;
import structures: Program;

void main(string[] arguments) {
    SymbolTable table = new SymbolTable;
    Lexer lexer = new Lexer(table);
    lexer.process_source(arguments);
    //lexer.print_tokens();
    Program* program = parse_program(lexer, arguments[1]);
    semantic_analysis(program, table);
    //generate_assembly(program);
    writeln("Compilation Successful");
}