import lexing_tools;
import function_parsers;
import symbol_table;
import std.stdio: writeln;
import structures: Program;

void main(string[] arguments) {
    SymbolTable table = new SymbolTable;
    Lexer lexer = new Lexer(table);
    lexer.process_source(arguments);
    Program* program = parse_tokens(lexer, arguments[1]);
    //analyze_semantics(program, table);
    //generate_assembly(program);
    writeln("Compilation Successful");
}