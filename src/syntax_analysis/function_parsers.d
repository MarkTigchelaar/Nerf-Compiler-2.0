module function_parsers;

import std.stdio: writeln, write;
import NewSymbolTable;
import stack;
import fn_header_syntax_errors;
import structures: Statement, Variable, PrimitiveTypes;
import functions: Function;
import Lexer;
import statement_parsers: StatementParser;

class Parser {

    private Lexer lexer;
    private Function func;
    private Stack!string seperators;
    private int scope_depth;
    private StatementParser statements;

    this(Lexer lexer) {
        this.lexer = lexer;
        scope_depth = 0;
        seperators = new Stack!string;
        this.statements = new StatementParser(lexer);
    }


    public Function[] parse() {
        Function[] program;
        seperators = new Stack!string;
        
        while(lexer.has_tokens()) {
            parse_function_header();
            parse_function_body();
            program ~= func;
            func = null;
        }
        return program;
    }

    private void parse_function_header() {
        if(!is_fn_identifier(lexer.next_token())) {
            no_fn_keyword();
        }
        string name = get_function_name();
        func = new Function(name);
        get_parsed_function_args();
        set_function_return_type(name);
    }

    private string get_function_name() {
        string name = lexer.next_token();
        if(is_seperator(name) && is_prefix(name)) {
            no_fn_name();
        } else if(!is_valid_variable(name) || is_keyword(name)) {
            invalid_identifier_name();
        }
        return name;
    }

    private void get_parsed_function_args() {
        if(!lexer.has_tokens()) {
            function_missing_arg_parens();
        }
        string token = lexer.next_token();
        if(!(is_open_seperator(token) && is_prefix(token))) {
            function_missing_arg_parens();
        }
        lexer.set_init_token_type_for_collection(token);
        string[] raw_args = lexer.collect_scoped_tokens();
        parse_arguments(raw_args);
        if(func.has_duplicate_func_args()) {
            duplicate_fn_args();
        }
    }

    private void parse_arguments(string[] raw_args) {
        if(raw_args.length == 0) {
            return;
        }
        check_first_and_last_positions(raw_args);
        Variable* argument = new Variable;
        foreach(long i, string arg_member; raw_args) {
            final switch(get_position_of_arg(i)) {
                case 0:
                    argument.type = enforce_key_word(arg_member);
                    break;
                case 1:
                    argument.name = enforce_variable(arg_member);
                    func.add_argument(argument);
                    argument = new Variable;
                    break;
                case 2:
                    if(i == raw_args.length - 1) {
                        fn_args_missing_or_invalid_type();
                    }
                    break;
            }
        }
    }

    private void check_first_and_last_positions(string[] raw_args) {
        string last_item = raw_args[raw_args.length -1];
        if(raw_args.length == 1) {
            fn_args_missing_or_invalid_type();
        } else if(!is_valid_variable(last_item) ||
                is_keyword(last_item)) {
            invalid_identifier_name();
        }
    }

    private int get_position_of_arg(long index) {
        return index % 3;
    }

    private int enforce_key_word(string arg_member) {
        int type;
        switch(arg_member) {
            case "int":
                type = PrimitiveTypes.Integer;
                break;
            case "int[]":
                type = PrimitiveTypes.IntArray;
                break;
            case "bool":
                type = PrimitiveTypes.Bool;
                break;
            case "bool[]":
                type = PrimitiveTypes.BoolArray;
                break;
            case "char":
                type = PrimitiveTypes.Character;
                break;
            case "char[]":
                type = PrimitiveTypes.CharArray;
                break;
            default:
                unknown_type();
        }
        return type;
    }

    private string enforce_variable(string arg_member) {
        if(is_valid_variable(arg_member)) {
            return arg_member;
        } else {
            invalid_identifier_name();
            return null;
        }
    }

    private void enforce_comma(string arg_member) {
        if(!is_comma(arg_member)) {
            malformed_args();
        }
    }

    private void set_function_return_type(string func_name) {
        string return_type = lexer.next_token();
        if(is_primitive_type(return_type)) {
            func.add_return(enforce_key_word(return_type));
        } else {
            missing_or_invalid_return_type();
        }
    }

    private void parse_function_body() {
        if(!lexer.has_tokens()) {
            missing_or_invalid_function_body_start_token();
        }
        string token = lexer.next_token();
        if(!(is_open_seperator(token) && !is_prefix(token))) {
            missing_or_invalid_function_body_start_token();
        }
        lexer.set_init_token_type_for_collection(token);
        lexer.take_tokens_of_deeper_scope();
        if(!lexer.has_tokens()) {
            empty_func_body();
        } else {
            statements.set_function(func);
            statements.parse();
        }
        lexer.restore_previous_scope_level();

    }
}
/*
// See system_test.py for unhappy path testing.
unittest {
    string[] test = ["fn", "func", "(", ")", "void", "{", "return", ";","}"];

    Lexer lexer = new Lexer(test.dup);
    Parser parser = new Parser(lexer);
    Program* p = parser.parse();
    assert(p.functions.length == 1);
    assert(p.functions[0] !is null);
    assert(p.functions[0].get_name() == "func");
    //assert(p.functions[0].arguments.length == 0);
}
/*
unittest {
    string[] test = ["fn", "func", "(", ")", "void", "{", "return", ";","}",
                     "fn", "funcb", "(", "int", "a", ",", "float", "b",
                     ")", "void", "{", "return", ";","}"];
    SymbolTable table = new SymbolTable;
    Lexer lexer = new Lexer(table, test.dup);
    ScopedTokenCollector collector = new ScopedTokenCollector(table);
    Program* p = parse_program(lexer, "test");
    string[] func_arg_types = table.get_function_args("func");
    assert(func_arg_types is null);

    string[] funcb_arg_types = table.get_function_args("funcb");
    assert(funcb_arg_types !is null);
    assert(funcb_arg_types.length == 2);
    assert(funcb_arg_types[0] == "int");
    assert(funcb_arg_types[1] == "float");
    
    Function*[] funcs = p.functions;
    assert(p.name == "test");
    assert(funcs.length == 2);
    assert(funcs[1] !is null);
    assert(funcs[1].name == "funcb");
    assert(funcs[1].arg_names.length == 2);
    assert(funcs[1].arg_names[0] == "a");
    assert(funcs[1].arg_names[1] == "b");
}
*/