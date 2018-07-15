import lexing_tools;
import symbol_table;
import std.stdio: writeln;

void main(string[] arguments) {
    SymbolTable table = new SymbolTable;
    Lexer lexer = new Lexer(table);
    lexer.process_source(arguments);
    //lexer.print_tokens();

}