import lexing_tools;
import function_parsers;
import symbol_table;
import std.stdio: writeln;
import structures: Program;
import syntax_errors;

void main(string[] arguments) {
    SymbolTable table = new SymbolTable;
    Lexer lexer = new Lexer(table);
    lexer.process_source(arguments);
    //lexer.print_tokens();
    Program* program = parse_tokens(lexer, arguments[1]);
    // analyze_semantics(program, table);
    // generate_assembly(program);
}