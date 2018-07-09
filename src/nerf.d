import lexing_tools;
import symbol_table;

void main(string[] arguments) {
    check_files(arguments);
    SymbolTable table = new SymbolTable;
    string[] source = lex(arguments[1], table);


}