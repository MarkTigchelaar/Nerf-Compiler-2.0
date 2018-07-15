module function_parsers;
import symbol_table;
//import structures;


Program* parse_tokens(Lexer lexer, string prog_name) {
    Program* program = new Program(prog_name);
    while(lexer.not_complete()) {
        Function* func = new Function;
        parse_function(lexer, func);
        program.functions ~= func;
    }
    return program;
}

void parse_function(Lexer lexer, Function* func) {
    import syntax_errors: no_fn_keyword;
    SymbolTable table;
    string token = lexer.get_token();
    table = lexer.get_table();
    if(table.is_fn_identifier(token)) {
        lexer.increment_stream_index();
        func.name = set_function_name(lexer, table);
    } else {
        no_fn_keyword();
    }
}

void set_function_name(Lexer lexer, SymbolTable table) {
    import syntax_errors: no_fn_name, invalid_identifier_name;
    string token = lexer.get_token();
    if(table.is_valid_variable(token)) {
        get_function_arguments(lexer, table);
    } else if(table.is_seperator(token)) {
        no_fn_name();
    } else {
        invalid_identifier_name();
    }
}

void get_function_arguments(Lexer lexer, SymbolTable table) {
    return;
}