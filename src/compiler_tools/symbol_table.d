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
    private:
        string[] key_word_table;
        string[] bools;
        int[string] math_operators;
        int[string] bool_comparison;
        string[string] open_seperators;
        string[string] close_seperators;
        string[string] variable_table;
        string[][int] variables_at_scope_level;
        int scope_level;
        string[][string] function_fn_args_table;
        string[string] function_return_types;

    public:
    this() {
        scope_level = 1;
        key_word_table = key_words();
        this.math_operators = get_math_operators();
        this.bool_comparison = get_bool_comparison();
        this.open_seperators = get_open_seperators();
        this.close_seperators = get_close_seperators();
        this.bools = ["&", "|", "!"];
    }

    final void scope_level_one_level_deeper() {
        scope_level++;
    }

    final void scope_level_one_level_shallower() {
        scope_level--;
        if(scope_level < 1) {
            throw new Exception("Scope is less than one.");
        }
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

    final bool is_declared_variable(string token) {
        if(token in variable_table) {
            return true;
        }
        return false;
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

    final string[] variables_at_this_level() {
        return variables_at_scope_level[scope_level];
    }

    final void add_variable(string variable, string type) {
        if(!is_declared_variable(variable)) {
            variable_table[variable] = type;
            variables_at_scope_level[scope_level] ~= variable;
        }
    }

    // arg types in order from left to right (for semantic analysis).
    final void add_fn_args(string fn_name, string[] arg_types) {
        import fn_header_syntax_errors: duplicate_fn_name;
        if(is_function_name(fn_name)) {
            duplicate_fn_name();
        } else {
            function_fn_args_table[fn_name] = arg_types;
        }
    }

    final void add_fn_return_type(string fn_name, string return_type) {
        import fn_header_syntax_errors: duplicate_fn_name;
        if(fn_name in function_return_types) {
            duplicate_fn_name();
        } else {
            function_return_types[fn_name] = return_type;
        }
    }

    final bool is_function_name(string fn_name) {
        if(fn_name in function_fn_args_table) {
            return true;
        }
        return false;
    }

    final string[] get_function_args(string func_name) {
        import semantic_errors: invalid_func_call;
        if(is_function_name(func_name)) {
            return function_fn_args_table[func_name];
        } else {
            invalid_func_call();
        }
        return null;
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

    final bool is_boolean(string token) {
        if(token == "True" || token == "False") {
            return true;
        }
        return false;
    }

    final bool is_partial_op(string token) {
        if(token == ":" || token == "<" || token == ">") {
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

    final int token_precedence(string token) {
        if(is_valid_variable(token) || is_keyword(token) || is_number(token)) {
            return 0;
        } else if(is_bool_compare(token)) {
            return bool_comparison[token];
        } else if(is_bool_operator(token)) {
            return bool_op_precedence(token);
        } else if(is_math_op(token)) {
            return math_operators[token];
        } else {
            throw new Exception("unknown token type.");
        }
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