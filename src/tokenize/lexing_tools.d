module lexing_tools;

import lexing_errors;
import symbol_table: SymbolTable;
import stack: Stack;
import std.ascii: isWhite;

class Lexer {
    private string[] tokens;
    private string candidate;
    private ulong index;
    private SymbolTable table;
    private Stack stk;

    this(SymbolTable table) {
        index = 0;
        this.table = table;
        this.stk = new Stack;
    }

    this(SymbolTable table, string[] test_tokens) {
        this(table);
        tokens = test_tokens;
    }

    public void process_source(string[] arguments) {
        check_files(arguments);
        process_file(arguments[1]);
    }

    public string get_token() {
        if(index >= tokens.length) {
            return null;
        }
        return tokens[index];
    }

    public void increment_stream_index() {
        index++;
        if(index > tokens.length) {
            throw new Exception("Lexer exceeded token stream length.");
        }
    }

    public bool not_complete() {
        return index < tokens.length;
    }

    final SymbolTable get_table() {
        return table;
    }

    private void check_files(string[] arguments) {
        import std.algorithm: endsWith;
        import core.sys.posix.stdlib: exit;
        import std.stdio;
        if(arguments.length < 2) {
            exit(-1);
        } else if(arguments.length > 2) {
            multiple_files();
        }
        if(! endsWith(arguments[1], ".nerf")) {
            bad_file_extension();
        }
    }

    private void process_file(string file_name) {
        import std.stdio: File;
        import std.string: chomp, strip;
        import lexing_errors: mismatched_tokens;
        File file;
        string rawline;
        try {
            file  = File(file_name, "r");
        } catch(Exception exc) {
            file_not_found();
        } finally {
            while(!file.eof()) {
                rawline ~= chomp(file.readln());
            }
            file.close();
            rawline = strip(rawline);
            if(rawline.length < 1) {
                empty_file();
            }
            if(!check_seperators(rawline)) {
                mismatched_tokens();
            }
            tokenize(rawline);
        }
    }

    private bool check_seperators(string tokstream) {
        string tok;
        stk.clear();
        foreach(char ch; tokstream) {
            tok ~= ch;
            if(table.is_open_seperator(tok)) {
                stk.push(tok);
            } else if(table.is_close_seperator(tok)) {
                if(stk.peek()!= table.get_close_match(tok)) {
                    return false;
                }
                stk.pop();
            }
            tok = "";
        }
        if(!stk.isEmpty()) {
            return false;
        }
        return true;
    }
    import std.stdio: writeln, write;
    private void tokenize(string stream) {
        string trailing;
        string leading;
        foreach(char ch; stream) {
            trailing = "" ~ ch;
            if(is_part_of_valid_token(trailing)) {
                if(table.is_partial_op(candidate)) {
                    add_candidate();
                }
                candidate ~= trailing;
            } else if(table.is_partial_op(trailing)) {
                tokenize_partial_ops(trailing);
            } else {
                add_candidate();
                determine_token_type(trailing);
            }
        }
        if(is_part_of_valid_token(candidate)) {
            add_candidate();
        }
    }

    private bool is_part_of_valid_token(string part) {
        if(table.is_valid_variable(candidate ~ part)) {
            return true;
        } else if(table.is_keyword(candidate ~ part)) {
            return true;
        } else if(table.is_number(part)) {
            return true;
        }  else if(table.is_dot(part)) {
            return true;
        } else {
            return false;
        }
    }

    private void tokenize_partial_ops(string part) {
        if(candidate.length < 1) {
            candidate = part;
        } else if(table.is_operator(candidate ~ part) ) {
            candidate ~= part;
            add_candidate();
        } else if(table.is_assignment(candidate ~ part)) {
            candidate ~= part;
            add_candidate();
        } else if(table.is_partial_op(candidate)) {
            add_candidate();
        } else {
            add_candidate();
            candidate ~= part;
        }
    }

    private void determine_token_type(string type) {
        if(table.is_terminator(type) ||
           table.is_operator(type)   ||
           table.is_seperator(type))
        {
            candidate = type;
            add_candidate();
        } else if(table.is_partial_op(type)) {
            candidate = type;
        } else if(table.is_valid_variable(type)) {
            candidate = type;
        }
    }

    private void add_twice(string added_chars) {
        add_candidate();
        candidate = "" ~ added_chars;
        add_candidate();
    }

    private void add_candidate() {
        if(candidate !is null) {
            tokens ~= candidate;
            candidate = null;
        }
    }

    public void print_tokens() {
        import std.stdio: writeln, write;
        int indent_val = 0;
        string indent;
        if(!table.is_seperator("{") ||
           !table.is_seperator("}") ||
           !table.is_terminator(";")) {
               throw new Exception(
            "Indentation using tokens that are no longer part of language.");
           }
        foreach(string tok; tokens) {

            
            if(tok == "{") {
                indent = "";
                write("\'" ~ tok ~ "\' ");
                indent_val += 2;
                writeln();
                for(int i = 0; i < indent_val; i++) {
                    indent ~= " ";
                }
                write(indent);
            } else if(tok == "}") {
                indent_val -= 2;
                indent = "";
                for(int i = 0; i < indent_val; i++) {
                    indent ~= " ";
                }
                writeln();
                writeln(indent ~ "\'" ~ tok ~ "\' ");
                
            } else if(tok == ";") {
                writeln("\'" ~ tok ~ "\' ");
                for(int i = 0; i < indent_val; i++) {
                    indent ~= " ";
                }
            } else {
                write(indent ~ "\'" ~ tok ~ "\' ");
                indent = "";
            }
        }
    }
}





unittest {
    SymbolTable s = new SymbolTable;
    Lexer l = new Lexer(s);
    assert(!l.check_seperators("{{{ }}} )"));
    assert(!l.check_seperators("{(})"));
    assert(!l.check_seperators("{{{{ }}}"));
    assert(l.check_seperators("(){}a"));
    assert(l.check_seperators("{ { {} () test {} }}"));
    assert(!l.check_seperators("}{"));
}

unittest {
    SymbolTable s = new SymbolTable;
    Lexer l = new Lexer(s);
    string test;
    string[] expect;

    test = "fn main() void { \n
              if(i<=j) { \n
                int k:=12; \n
              } \n
            }";
    expect = ["fn","main","(",")","void",
              "{","if","(","i","<=","j",")",
              "{","int","k",":=","12",";","}",
              "}"];
    l.tokenize(test);
    assert(l.tokens.length == expect.length);
    for(int i = 0; i < expect.length; i++) {
        assert(l.tokens[i] == expect[i]);
    }
}

unittest {
    SymbolTable s = new SymbolTable;
    Lexer l = new Lexer(s);
    string test = "<= c:=d a<b d>=e != f==g;";
    string[] expect = ["<=", "c", ":=", "d", "a",
                       "<", "b", "d", ">=", "e",
                       "!=", "f", "==", "g", ";"];
    l.tokenize(test);
    assert(l.tokens.length == expect.length);
    for(int i = 0; i < expect.length; i++) {
        assert(l.tokens[i] == expect[i]);
    }
}

unittest {
    SymbolTable s = new SymbolTable;
    Lexer l = new Lexer(s);
    string test;
    string[] expect;

    test = "bool t := (a + c ^d) < (d^d + (72*18^e);";
    expect = ["bool", "t", ":=", "(", "a",
               "+", "c", "^", "d", ")", "<", "(",
               "d", "^", "d", "+", "(", "72", "*",
               "18", "^", "e", ")", ";"];
    l.tokenize(test);
    assert(l.tokens.length == expect.length);
    for(int i = 0; i < expect.length; i++) {
        assert(l.tokens[i] == expect[i]);
    }
}

unittest {
    SymbolTable s = new SymbolTable;
    Lexer l = new Lexer(s);
    string test;
    string[] expect;

    test = "inty booly floaty fny breakr 
             returnn whiley continueo";
    expect = ["inty", "booly", "floaty", "fny",
              "breakr", "returnn", "whiley","continueo"];
    
    l.tokenize(test);
    assert(l.tokens.length == expect.length);
    for(int i = 0; i < l.tokens.length; i++) {
        assert(l.tokens[i] == expect[i]);
    } 
}

