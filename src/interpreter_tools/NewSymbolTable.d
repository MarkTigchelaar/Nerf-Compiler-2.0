module NewSymbolTable;

bool is_valid_variable(string variable) {
    return regex_helper(variable, `^[a-zA-Z_]+$`) &&
            !is_keyword(variable);
}

bool is_number(string variable) {
    return is_variable_integer(variable) ||
        is_variable_float(variable);
}

bool is_variable_integer(string variable) {
    return regex_helper(variable, `^([1-9]\d*|0)$`);
}

bool is_variable_char(string variable) {
    char[] str = cast(char[]) variable;
    if(str.length != 3) {
        return false;
    }
    if(str[0] != '\'') {
        return false;
    }
    if(str[str.length - 1 != '\'']) {
        return false;
    }
    return true;
}

bool is_variable_float(string variable) {
    return regex_helper(variable, `^[0-9]+[.][0-9]+$`);
}

bool regex_helper(string variable, string expression) {
    import std.regex;
    auto m = matchFirst(variable, regex(expression));
    return !m.empty;
}

bool is_partial_op(string token) {
    if(token == ":" || token == "<" || 
        token == ">" || token == "=" || 
        token == "!") {
        return true;
    }
    return false;
}

bool is_primitive_type(string token) {
    string[] pt =["int", "bool", "char", "int[]", "bool[]", "char[]"];
    foreach(string str; pt) {
        if(token == str) {
            return true;
        }
    }
    return false;
}

bool is_right_associative(string token) {
    return token == "^";
}

bool is_return(string token) {
    return token == "return";
}

bool is_break(string token) {
    return token == "break";
}

bool is_continue(string token) {
    return token == "continue";
}

bool is_if(string token) {
    return token == "if";
}

bool is_else(string token) {
    return token == "else";
}

bool is_while(string token) {
    return token == "while";
}

bool is_fn_identifier(string token) {
    return token == "fn";
}

bool is_print(string token) {
    return token == "print";
}

bool is_open_curly_brace(string token) {
    return token == "{";
}

bool is_open_paren(string token) {
    return token == "(";
}

bool is_curly_brace(string token) {
    return is_open_curly_brace(token) || token == "}";
}

bool is_close_paren(string token) {
    return token == ")";
}

bool is_void(string token) {
    return token == "void";
}

bool is_program_entry_point(string token) {
    return token == "main";
}

string get_entry_point() {
    return "main";
}

bool is_dot(string token) {
    return token == ".";
}

bool is_assignment(string token) {
    return token == ":=";
}

bool is_comma(string token) {
    return token == ",";
}

bool is_terminator(string token) {
    return token == ";";
}

bool is_seperator(string token) {
    string[] seps = ["(", ")", "{", "}", "[", "]", ","];
    foreach(string sep; seps) {
        if(sep == token) {
        return true;
        }
    }
    return false;
}

bool is_open_seperator(string token) {
    string[] open = ["(", "{", "["];
    foreach(string sep; open) {
        if(sep == token) {
        return true;
        }
    }
    return false;
}

bool is_close_seperator(string token) {
    string[] close = [")", "}", "]"];
    foreach(string sep; close) {
        if(sep == token) {
        return true;
        }
    }
    return false;
}

bool is_boolean(string token) {
    if(token == "True" || token == "False") {
        return true;
    }
    return false;
}

int bool_op_precedence(string token) {
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

int token_precedence(string token) {
    if(is_valid_variable(token) || is_keyword(token) || is_number(token)) {
        return 0;
    } else if(is_bool_compare(token)) {
        return get_bool_comparison()[token];
    } else if(is_bool_operator(token)) {
        return bool_op_precedence(token);
    } else if(is_math_op(token)) {
        return get_math_operators()[token];
    } else if(is_open_paren(token)) {
        return fn_call_precedence();
    } else {
        throw new Exception("unknown token type.");
    }
}

int prefix_precedence(string token) {
    if(token == "-" || token == "!") {
        return 7;
    } else if(token == "(") {
        return 8;
    } else {
        throw new Exception("token " ~ token ~ "is not a prefix");
    }
} 

bool is_minus(string token) {
    return token == "-";
}

int fn_call_precedence() {
    return 8;
}

bool is_operator(string token) {
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

bool is_bool_compare(string token) {
    if(token in get_bool_comparison()) {
        return true;
    }
    return false; 
}

bool is_bool_operator(string token) {
    string[] bools = ["&", "|", "!"];
    foreach(string boolean; bools) {
        if(token == boolean) {
            return true;
        }
    }
    return false;
}

bool is_math_op(string token) {
    if(token in get_math_operators()) {
        return true;
    }
    return false; 
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

bool is_prefix(string token) {
    if(token == "-" || token == "!" || token == "(") {
    return true;
    }
    return false;
}

bool is_garbage(string tok) {
    string[] bad = ["!", "@", "#", "$", "%", "^", "&", "*", "~"];
    foreach(string b; bad) {
        if(b == tok) {
            return true;
        }
    }
    return false;
}

string[] get_reserved_words() {
    string[] kw = [
        "fn",
        "int",
        "char",
        "bool",
        "int[]",
        "char[]",
        "bool[]",
        "True",
        "False",
        "return",
        "print",
        "void",
        "while",
        "break",
        "continue",
        "if",
        "else",
        ":=",
        "+",
        "/",
        "-",
        "*",
        "%",
        "^",
        ">",
        "<",
        "<=",
        ">=",
        "==",
        "!=",
        "!",
        "&",
        "|",
        "{",
        "}",
        "(",
        ")",
        "[",
        "]",
        ",",
        "\"",
        "'",
        ";"
    ];

    return kw;
}

bool is_keyword(string token) {
    foreach(string word; key_words()) {
        if(token == word) {
            return true;
        }
    }

    return false;
}

string[string] get_open_seperators() {
    string[string] seperators;
    seperators["{"] = "}";
    seperators["("] = ")";
    return seperators;
}

string get_close_match(string sep) {
    string match;
    switch(sep) {
        case "{":
            match = "}";
            break;
        case "}":
            match = "{";
            break;      
        case "(":
            match = ")";
            break;
        case "[":
            match = "]";
            break;
        case "]":
            match = "[";
            break;
        case ")":
            match = "(";
            break;
        default:
           throw new Exception("No match found.");
    }
    return match;    
}

string[] key_words() {
        string[] kw = [
            "fn",
            "int",
            "char",
            "bool",
            "int[]",
            "char[]",
            "bool[]",
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

int set_type_code(string type) {
    import structures: PrimitiveTypes;
    int type_code;
    switch(type) {
        case "int":
            type_code = PrimitiveTypes.Integer;
            break;
        case "int[]":
            type_code = PrimitiveTypes.IntArray;
            break;
        case "bool":
            type_code = PrimitiveTypes.Bool;
            break;
        case "bool[]":
            type_code = PrimitiveTypes.BoolArray;
            break;
        case "char":
            type_code = PrimitiveTypes.Character;
            break;
        case "char[]":
            type_code = PrimitiveTypes.CharArray;
            break;
        default:
            throw new Exception("ERROR: unknown type.");
    }
    return type_code;
}