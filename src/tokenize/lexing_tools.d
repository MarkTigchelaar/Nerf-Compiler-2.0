module lexing_tools;

import core.sys.posix.stdlib: exit;
import lexing_errors;
import std.algorithm: endsWith;
import std.stdio: File;
import std.string: chomp;
import symbol_table: SymbolTable;
import stack: Stack;


class Lexer {
    private string[] tokens;
    private string candidate;
    private ulong index;
    private SymbolTable table;
    private Stack stk;

    this(SymbolTable table) {
        this.table = table;
        this.stk = new Stack;
    }

    public void process_source(string[] arguments) {
        check_files(arguments);
        process_file(arguments[1]);
    }

    private void check_files(string[] arguments) {
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
        File file;
        string rawline;
        string stream;
        import std.string: strip;
        try {
            file  = File(file_name, "r");
        } catch(Exception exc) {
            file_not_found();
        } finally {
            while(!file.eof()) {
                rawline ~= chomp(file.readln());
            }
            file.close();
            stream = streamlines(strip(rawline));
            if(stream.length < 1) {
                empty_file();
            }
            check_seperators(stream);
            tokenize(stream);
        }
    }

    private string streamlines(string rawline) {
        import std.regex;
        auto re = regex(`\s\s+`);
        return replaceAll(rawline, re, " ");
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
        import std.ascii: isWhite;
        string check;
        foreach(char ch; stream) {
            if(isWhite(ch)) {
                check = "";
                add_candidate();
                continue;
            }
            check ~= ch;
            if(check_runthrough(check, ch)) {
                continue;
            }
            candidate ~= ch;
            if(check_candidate()) {
                continue;
            }
            check = "";
        }
    }

    private bool check_runthrough(string check, char ch) {
        if(table.is_seperator(check)) {
            add_candidate();
        } else if(table.is_partial_op(check)) {
            add_candidate();
            candidate ~= ch;
            return true;
        } else if(table.is_bool_operator(check)) {
            add_candidate();
        } else if(table.is_terminator(check)) {
            add_candidate();
        } else if(table.is_math_op(check)) {
            add_candidate();
        }
        if(table.is_bool_compare(candidate)) {
            add_candidate();
        }
        return false;
    }

    private bool check_candidate() {
        if(table.is_keyword(candidate)) {
            add_candidate();
            return true;
        }
        if(table.is_seperator(candidate)) {
            add_candidate();
        } else if(table.is_bool_compare(candidate)) {
            add_candidate();
        } else if(table.is_bool_operator(candidate)) {
            add_candidate();
        } else if(table.is_terminator(candidate)) {
            add_candidate();
        } else if(table.is_math_op(candidate)) {
            add_candidate();
        }
        return false;
    }

    private void add_candidate() {
        if(candidate !is null) {
            tokens ~= candidate;
            candidate = null;
        }
    }

    public void print_tokens() {
        import std.stdio: writeln;
        foreach(string tok; tokens) {
            writeln("\'" ~ tok ~ "\'");
        }
    }
}

unittest {
    SymbolTable s = new SymbolTable;
    Lexer l = new Lexer(s);
    string expect = "fn main ( )";
    string arg = "fn    main    (   )";
    assert(l.streamlines(arg) == expect);
}

unittest {
    SymbolTable s = new SymbolTable;
    Lexer l = new Lexer(s);
    assert(!l.check_seperators("{{{ }}} )"));
    assert(!l.check_seperators("{(})"));
    assert(!l.check_seperators("{{{{ }}}"));
    assert(l.check_seperators("(){}a"));
    assert(l.check_seperators("{ { {} () test {} }}"));
}

unittest {
    SymbolTable s = new SymbolTable;
    Lexer l = new Lexer(s);
    string test;
    string[] expect;

    test = "fn main() void { \n
              if(i<j) { \n
                int k:=12; \n
              } \n
            }";
    expect = ["fn","main","(",")","void",
              "{","if","(","i","<","j",")",
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