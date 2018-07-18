module function_parsers;

import symbol_table;
import structures;
import lexing_tools;
import scoped_token_collector;
import std.stdio;

Program* parse_tokens(Lexer lexer, string prog_name) {
    Program* program = new Program(prog_name);
    auto table = lexer.get_table();
    auto collector = new ScopedTokenCollector(table);
    Function* func;
    while(lexer.not_complete()) {
        parse_function_header(lexer, func, collector);
        parse_function_body(lexer, func, collector);
        program.functions ~= func;
        func = null;
    }
    return program;
}

void parse_function_header(Lexer lexer, out Function* func,
        ScopedTokenCollector collector) {
    import syntax_errors: no_fn_keyword;
    auto table = lexer.get_table();
    if(table.is_fn_identifier(lexer.get_token())) {
        string name = get_function_name(lexer);
        string[] args = get_parsed_function_args(lexer, collector);
        set_function_return_type(lexer, name);
        func = new Function(name, args.dup);
    } else {
        no_fn_keyword();
    }
}

string get_function_name(ref Lexer lexer) {
    import syntax_errors: no_fn_name, invalid_identifier_name;
    auto table = lexer.get_table();
    lexer.increment_stream_index();
    string name = lexer.get_token();
    if(table.is_valid_variable(name) && !table.is_keyword(name)) {
        return name;
    } else if(table.is_seperator(name) && table.is_prefix(name)) {
        no_fn_name();
    } else {
        invalid_identifier_name();
    }
    return name;
}

string[] get_parsed_function_args(ref Lexer lexer,
        ref ScopedTokenCollector collector) {
    import syntax_errors: function_missing_arg_parens;
    auto table = lexer.get_table();
    string name = lexer.get_token();
    lexer.increment_stream_index();
    string token = lexer.get_token();
    if(!(table.is_open_seperator(token) && table.is_prefix(token))) {
        function_missing_arg_parens();
    }
    string[] raw_args = collect_tokens(lexer, collector);
    return parse_arguments(raw_args, table, name);
}

string[] collect_tokens(ref Lexer lexer,
        ref ScopedTokenCollector collector) {
    collector.add_token(lexer.get_token());
    do { // no worry about hitting eof, lexer has already checked brackets.
        lexer.increment_stream_index();
        collector.add_token(lexer.get_token());
    } while(collector.not_done_collecting());
    return collector.get_scoped_tokens();
}

string[] parse_arguments(string[] raw_args,
        ref SymbolTable table, string func_name) {
    import syntax_errors:
        invalid_identifier_name,
        malformed_args;

    string[] arg_types;
    string[] arg_names;
    
    if(raw_args.length == 0) {
        table.add_fn_args(func_name, null);
        return null;
    }
    check_first_and_last_positions(raw_args, table);
    foreach(int i, string arg_member; raw_args) {
        final switch(get_position_of_arg(i)) {
            case 0:
                arg_types ~= enforce_key_word(arg_member, table);
                break;
            case 1:
                arg_names ~= enforce_variable(arg_member, table);
                break;
            case 2:
                enforce_comma(arg_member, table);
                break;
        }
    }
    table.add_fn_args(func_name, arg_types);
    return arg_names;
}

void check_first_and_last_positions(string[] raw_args,
        ref SymbolTable table) {
    import syntax_errors:
    fn_args_missing_or_invalid_type,
    invalid_identifier_name;
    string last_item = raw_args[raw_args.length -1];
    if(raw_args.length == 1) {
        fn_args_missing_or_invalid_type();
    } else if(!table.is_valid_variable(last_item) ||
               table.is_keyword(last_item)) {
        invalid_identifier_name();
    }
}

int get_position_of_arg(int index) {
    return index % 3;
}

string enforce_key_word(string arg_member, ref SymbolTable table) {
    import syntax_errors: malformed_args;
    if(table.is_primitive_type(arg_member)) {
        return arg_member;
    } else {
        malformed_args();
        return null;
    }
}

string enforce_variable(string arg_member, ref SymbolTable table) {
    import syntax_errors: invalid_identifier_name;
    if(table.is_valid_variable(arg_member)) {
        return arg_member;
    } else {
        invalid_identifier_name();
        return null;
    }
}

void enforce_comma(string arg_member, ref SymbolTable table) {
    import syntax_errors:malformed_args;
    if(!table.is_comma(arg_member)) {
        malformed_args();
    }
}

void set_function_return_type(ref Lexer lexer, string func_name) {
    import syntax_errors: missing_or_invalid_return_type;
    SymbolTable table = lexer.get_table();
    lexer.increment_stream_index();
    string return_type = lexer.get_token();
    if(table.is_primitive_type(return_type)) {
        table.add_fn_return_type(func_name, return_type);
    } else {
        missing_or_invalid_return_type();
    }
}


void parse_function_body(ref Lexer lexer,  out Function* func,
        ref ScopedTokenCollector collector) {
    import syntax_errors: 
        missing_or_invalid_function_body_start_token,
        empty_func_body;
    SymbolTable table = lexer.get_table();
    lexer.increment_stream_index();
    string token = lexer.get_token();
    if(!(table.is_open_seperator(token) && !table.is_prefix(token))) {
        missing_or_invalid_function_body_start_token();
    }
    string[] func_body = collect_tokens(lexer, collector);
    lexer.increment_stream_index();
    if(func_body.length == 0) {
        empty_func_body();
    } /*else {
        func.stmts = parse_statements(func_body);
    }*/
}

/*
unittest {
    string[] test = ["fn", "func", "(", "int", "i", ")", "void"];
    SymbolTable table = new SymbolTable;
    Lexer lexer = new Lexer(table, test.dup);
    ScopedTokenCollector collector = new ScopedTokenCollector(table);
    Function* func;
    Program* p = parse_tokens(lexer, "testing");
    assert(p.name is "testing");
    assert(p.functions.length == 1);
    func = p.functions[0];
    assert(func.arg_names[0] == "i");
}*/