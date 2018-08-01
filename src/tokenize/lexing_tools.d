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

    private void tokenize(string stream) {
        string trailing;
        string leading;
        for(int i = 1; i < stream.length; i++) {
            trailing = "" ~ stream[i-1];
            leading = "" ~ stream[i];
            if(isWhite(stream[i-1])) {
                add_candidate();
            } else if(table.is_terminator(trailing)) {
                add_twice(trailing);
            } else if(table.is_partial_op(trailing)
                && table.is_operator(trailing ~ leading)) {
                    add_twice(trailing ~ leading);
                    i++;
            } else if(table.is_partial_op(trailing)
                && table.is_assignment(trailing ~ leading)) {
                    add_twice(trailing ~ leading);
                    i++;
            } else if(table.is_operator(trailing)) {
                add_twice(trailing);
            } else if(table.is_seperator(trailing)) {
                add_twice(trailing);
            } else {
                candidate ~= trailing;
            }
            if(i == stream.length - 1) {
                if(table.is_seperator(leading) || table.is_terminator(leading)) {
                    add_twice(leading);
                } else {
                    candidate ~= leading;
                    add_candidate();
                }
            }
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
