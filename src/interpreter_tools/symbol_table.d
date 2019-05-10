module symbol_table;

/*
    Symbol Table:
    Defines the tokens for the language.
    Everything is hard coded here, so that method calls can be used instead of raw string
    comparisons. This prevents technical debt from duplication
    of hard coded strings during syntax, and semantic analysis.
    It also serves to keep the workings of each phase of compilation abstract enough 
    to be though about as types and process steps, not specific strings.
    Contains several methods that simply return a bool if matching a type of keyword,
    or pattern (for recursive descent parsing).
    Errors in the "language" are handed as system exits in the error files.
    All exceptions are used to highlight incorrect runtime behaviour in the compiler itself.
*/
class SymbolTable {
    import program_state_manager;
    private:
        string[] key_word_table;
        string[] bools;
        int[string] math_operators;
        int[string] bool_comparison;
        string[string] open_seperators;
        string[string] close_seperators;
        string[string] operation_table;
        ProgramStateManager state_mgmt;

    public:
    this() {
        key_word_table = key_words();
        this.math_operators = get_math_operators();
        this.bool_comparison = get_bool_comparison();
        this.open_seperators = get_open_seperators();
        this.close_seperators = get_close_seperators();
        this.bools = ["&", "|", "!"];
        state_mgmt = new ProgramStateManager;
        operation_table = make_operation_table();
    }

    final string[string] get_operation_table() {
        return operation_table;
    }

    final string get_asm_operator(string op) {
        return operation_table[op];
    }

    final ProgramStateManager get_state_mgmt() {
        return state_mgmt;
    }

    final int current_scope_level() {
        return state_mgmt.current_scope_level();
    }
    
    final void scope_level_one_level_deeper() {
        state_mgmt.inc_scope_level();
    }

    final void scope_level_one_level_shallower() {
        state_mgmt.dec_scope_level();
    }

    final bool is_seperator(string token) {
        if((token in open_seperators) ||
           (token in close_seperators) ||
             token == ",") {
            return true;
        }
        return false;
    }

    final bool is_close_seperator(string token) {
        if(token in close_seperators) {
            return true;
        }
        return false;
    }

    final bool is_open_seperator(string token) {
        if(token in open_seperators) {
            return true;
        }
        return false;
    }

    final string get_open_match(string token) {
        return open_seperators[token];
    }

    final string get_close_match(string token) {
        return close_seperators[token];
    }

    final bool is_prefix(string token) {
        if(token == "-" || token == "!" || token == "(") {
            return true;
        }
        return false;
    }

    final int prefix_precedence(string token) {
        if(token == "-" || token == "!") {
            return 7;
        } else if(token == "(") {
            return 8;
        } else {
            throw new Exception("token " ~ token ~ "is not a prefix");
        }
    }

    final void clear_local_variables() {
       state_mgmt.clear_local_variables();
    }

    final bool is_declared_variable(string token) {
        return state_mgmt.is_declared_variable(token);
    }

    final is_valid_variable(string variable) {
        return regex_helper(variable, `^[a-zA-Z_]+$`) &&
                !is_keyword(variable);
    }

    final bool is_number(string variable) {
        return is_variable_integer(variable) ||
            is_variable_float(variable);
    }

    final bool is_variable_integer(string variable) {
        return regex_helper(variable, `^([1-9]\d*|0)$`);
    }

    final bool is_variable_float(string variable) {
        return regex_helper(variable, `^[0-9]+[.][0-9]+$`);
    }

    final void add_local_variable(string variable, string type) {
        state_mgmt.add_local_variable_type(variable, type);
    }

    final string get_local_variable_type(string variable) {
        return state_mgmt.get_local_variable_type(variable);
    }

    final void add_fn_return_type(string fn_name, string return_type) {
        state_mgmt.add_fn_return_type(fn_name, return_type);
    }

    final string get_return_type(string fn_name) {
       return state_mgmt.get_return_type(fn_name);
    }

    final bool is_function_name(string fn_name) {
        return state_mgmt.is_function_name(fn_name);
    }

    // arg types in order from left to right (for semantic analysis).
    final void add_fn_args(string fn_name, string[] arg_types) {
        state_mgmt.add_fn_args(fn_name, arg_types);
    }

    final string[] get_function_args(string func_name) {
        return state_mgmt.get_function_args(func_name);
    }

    final bool regex_helper(string variable, string expression) {
        import std.regex;
        auto m = matchFirst(variable, regex(expression));
        return !m.empty;
    }

    final bool is_keyword(string token) {
        foreach(string word; key_word_table) {
            if(token == word) {
                return true;
            }
        }
        return false;
    }

    final bool is_assignment(string token) {
        return token == ":=";
    }

    final bool is_comma(string token) {
        return token == ",";
    }

    final bool is_terminator(string token) {
        return token == ";";
    }

    final bool is_math_op(string token) {
        if(token in math_operators) {
            return true;
        }
        return false; 
    }

    final bool is_minus(string token) {
        return token == "-";
    }

    final bool is_bool_compare(string token) {
        if(token in bool_comparison) {
            return true;
        }
        return false; 
    }

    final bool is_bool_operator(string token) {
        foreach(string boolean; bools) {
            if(token == boolean) {
                return true;
            }
        }
        return false;
    }

    final bool is_operator(string token) {
        if(is_bool_compare(token)) {
            return true;
        }
        if(is_bool_operator(token)) {
            return true;
        }
        if(is_math_op(token)) {
            return true;
        }
        return false;
    }

    final int bool_op_precedence(string token) {
        if(token == "!") {
            return 7;
        } else if(token == "&") {
            return 2;
        } else if(token == "|") {
            return 1;
        } else {
            throw new Exception("Not a bool.");
        }
    }

    final int fn_call_precedence() {
        return 8;
    }

    final bool is_boolean(string token) {
        if(token == "True" || token == "False") {
            return true;
        }
        return false;
    }

    final bool get_bool(string arg) {
        if(arg == "True") {
            return true;
        } else if(arg == "False") {
            return false;
        } else {
            throw new Exception("expected bool, got something wrong.");
        }
    }

    final bool is_partial_op(string token) {
        if(token == ":" || token == "<" || 
           token == ">" || token == "=" || 
           token == "!") {
            return true;
        }
        return false;
    }

    final bool is_primitive_type(string token) {
        string[] pt =["int", "float", "bool", "void"];
        foreach(string str; pt) {
            if(token == str) {
                return true;
            }
        }
        return false;
    }

    final bool is_right_associative(string token) {
        return token == "^";
    }

    final bool is_return(string token) {
        return token == "return";
    }

    final bool is_break(string token) {
        return token == "break";
    }

    final bool is_continue(string token) {
        return token == "continue";
    }

    final bool is_if(string token) {
        return token == "if";
    }

    final bool is_else(string token) {
        return token == "else";
    }

    final bool is_while(string token) {
        return token == "while";
    }

    final bool is_fn_identifier(string token) {
        return token == "fn";
    }

    final bool is_print(string token) {
        return token == "print";
    }

    final bool is_open_curly_brace(string token) {
        return token == "{";
    }

    final bool is_open_paren(string token) {
        return token == "(";
    }

    final bool is_close_paren(string token) {
        return token == ")";
    }

    final bool is_void(string token) {
        return token == "void";
    }

    final bool is_program_entry_point(string token) {
        return token == "main";
    }

    final string get_entry_point() {
        return "main";
    }

    final bool is_dot(string token) {
        return token == ".";
    }
    
    final int token_precedence(string token) {
        if(is_valid_variable(token) || is_keyword(token) || is_number(token)) {
            return 0;
        } else if(is_bool_compare(token)) {
            return bool_comparison[token];
        } else if(is_bool_operator(token)) {
            return bool_op_precedence(token);
        } else if(is_math_op(token)) {
            return math_operators[token];
        } else if(is_open_paren(token)) {
            return fn_call_precedence();
        } else {
            throw new Exception("unknown token type.");
        }
    }

    final bool resolves_to_bool_value(string ast_type) {
        if(is_bool_operator(ast_type)) {
            return true;
        } else if(is_bool_compare(ast_type)) {
            return true;
        } else if(is_boolean(ast_type)) {
            return true;
        } else if(is_declared_variable(ast_type)) {
            return get_local_variable_type(ast_type) == "bool";
        } else if(ast_type == "bool") {
            return true;
        }
        return false;
    }

    final string get_bool() {
        return "bool";
    }

    final bool resolves_to_int(string ast_type) {
        if(is_math_op(ast_type)) {
            return true;
        } else if(is_variable_integer(ast_type)) {
            return true;
        } else if(ast_type == "int") {
            return true;
        } else if(is_declared_variable(ast_type)) {
            if(state_mgmt.get_local_variable_type(ast_type) == "int") {
                return true;
            } 
        }
        return false;
    }

    final string get_int() {
        return "int";
    }

    final bool resolves_to_float(string ast_type) {
        if(is_math_op(ast_type)) {
            return true;
        } else if(is_variable_float(ast_type)) {
            return true;
        } else if(ast_type == "float") {
            return true;
        } else if(is_declared_variable(ast_type)) {
            if(state_mgmt.get_local_variable_type(ast_type) == "float") {
                return true;
            } 
        }
        return false;
    }

    final string get_float() {
        return "float";
    }
}





private:

string[] key_words() {
    string[] kw = [
        "fn",
        "int",
        "float",
        "bool",
        "True",
        "False",
        "return",
        "print",
        "void",
        "while",
        "break",
        "continue",
        "if",
        "else"
    ];
    return kw;
}

int[string] get_math_operators() {
    int[string] ops;
    ops["+"] = 4;
    ops["/"] = 4;
    ops["-"] = 5;
    ops["*"] = 5;
    ops["%"] = 5;
    ops["^"] = 6;
    return ops;
}

int[string] get_bool_comparison() {
    int[string] bool_compare;
    bool_compare[">"] = 3;
    bool_compare["<"] = 3;
    bool_compare["<="] = 3;
    bool_compare[">="] = 3;
    bool_compare["=="] = 3;
    bool_compare["!="] = 3;
    return bool_compare;
}

string[string] get_open_seperators() {
    string[string] seperators;
    seperators["{"] = "}";
    seperators["("] = ")";
    return seperators;
}

string[string] get_close_seperators() {
    string[string] seperators;
    seperators["}"] = "{";
    seperators[")"] = "(";
    return seperators;
}

// for conversion from user defined types,
// into unchanging internal versions 
// used in evaluation stage.
string[string] make_operation_table() {
    string[string] op_table;
    op_table["+"] = "ADD";
    op_table["-"] = "SUB";
    op_table["*"] = "MULT";
    op_table["/"] = "DIV";
    op_table["^"] = "EXP";
    op_table["%"] = "MOD";
    op_table[">"] = "GT";
    op_table["<"] = "LT";
    op_table["<="] = "LTEQ";
    op_table[">="] = "GTEQ";
    op_table["!="] = "NOTEQ";
    op_table["=="] = "EQ";
    op_table["!"] = "NOT";
    op_table["&"] = "AND";
    op_table["|"] = "OR";
    return op_table;
}



unittest {
    SymbolTable s = new SymbolTable;
    assert(s.is_prefix("-"));
    assert(s.is_prefix("!"));
    assert(s.is_prefix("("));
    assert(!s.is_prefix("+"));
}

unittest {
    SymbolTable s = new SymbolTable;
    assert(s.is_keyword("int"));
    assert(s.is_keyword("fn"));
    assert(s.is_keyword("float"));
    assert(s.is_keyword("bool"));
    assert(s.is_keyword("True"));
    assert(s.is_keyword("False"));
    assert(s.is_keyword("return"));
    assert(s.is_keyword("print"));
    assert(s.is_keyword("void"));
    assert(s.is_keyword("while"));
    assert(s.is_keyword("break"));
    assert(s.is_keyword("continue"));
    assert(s.is_keyword("if"));
    assert(s.is_keyword("else"));
    assert(!s.is_keyword("2"));
    assert(!s.is_keyword("+"));
    assert(!s.is_keyword("<="));
}

unittest {
    SymbolTable s = new SymbolTable;
    assert(s.is_boolean("True"));
    assert(s.is_boolean("False"));
    assert(!s.is_boolean("true"));
    assert(!s.is_boolean("false"));
}

unittest {
    SymbolTable s = new SymbolTable;
    assert(s.token_precedence("+") == 4);
    assert(s.token_precedence("^") == 6);
    assert(s.token_precedence("==") == 3);
}

unittest {
    SymbolTable s = new SymbolTable;
    assert(s.is_variable_integer("3"));
    assert(!s.is_variable_integer("03"));
    assert(s.is_variable_integer("30010"));
    assert(!s.is_variable_integer("3ad"));
    assert(!s.is_variable_integer("30.6"));
    assert(!s.is_variable_integer("3-06"));
    assert(!s.is_variable_integer("-306"));
    assert(!s.is_variable_integer("306-"));
    assert(!s.is_variable_integer("#%^$%^%$^"));
}

unittest {
    SymbolTable s = new SymbolTable;
    assert(s.is_variable_float("3.0"));
    assert(s.is_variable_float("0.3"));
    assert(!s.is_variable_float("-3.0"));
    assert(!s.is_variable_float(".0"));
    assert(!s.is_variable_float("3.0.0"));
    assert(!s.is_variable_float("3.0a"));
    assert(!s.is_variable_float("a3.0"));
    assert(!s.is_variable_float("30"));
    assert(!s.is_variable_float("3."));
}

unittest {
    SymbolTable s = new SymbolTable;
    assert(!s.is_valid_variable("30"));
    assert(!s.is_valid_variable("3.0"));
    assert(!s.is_valid_variable("_abc#"));
    assert(!s.is_valid_variable("$abc"));
    assert(!s.is_valid_variable("9abc"));
    assert(!s.is_valid_variable("abc0"));
    assert(!s.is_valid_variable("CamelCas3"));
    assert(s.is_valid_variable("_abc"));
    assert(s.is_valid_variable("_abc_"));
    assert(s.is_valid_variable("_abc_defg"));
    assert(s.is_valid_variable("ab_cd"));
    assert(s.is_valid_variable("_"));
    assert(!s.is_valid_variable("True"));
    assert(s.is_valid_variable("Truthy"));
}