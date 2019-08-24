module Lexer;

import core.sys.posix.stdlib: exit;
import std.stdio: writeln;
import LexingErrors;
import NewSymbolTable;
import scoped_token_collector;
import stack;


class Lexer {

    private struct saved_tokens {
        int index;
        string[] tokens;
    }
    private int index;
    private string[] tokens;
    private string candidate;
    private ScopedTokenCollector collector;
    private saved_tokens*[] prev_state;
    private uint prev_state_index;

    this() {
        this.collector = new ScopedTokenCollector;
        this.prev_state = new saved_tokens*[100];
        this.prev_state_index = 0;
    }

    this(string toks) {
        this();
        tokenize(toks);
    }

    this(string[] toks) {
        //this();
        this.collector = new ScopedTokenCollector;
        this.prev_state = new saved_tokens*[100];
        this.prev_state_index = 0;
        tokens = toks;
    }

    public bool has_tokens() {
        return index < tokens.length;
    }

    public string next_token() {
        string tok = tokens[index];
        index++;
        return tok;
    }

    public void process_source(string[] args) {
        check_files(args);
        process_file(args[1]);
    }

    public void increment_stream_index() {
        index++;
    }

    public string[] collect_until_match(string token) {
        string tok;
        string[] toks;
        while(has_tokens()) {
            tok = next_token();
            if(token == tok) {
                return toks;
            }
            toks ~= tok;
        }
        statement_not_terminated();
        return null;
    }

    public void set_init_token_type_for_collection(string token) {
        collector.add_token(token);
    }

    public void take_tokens_of_deeper_scope() {
        string[] scoped_tokens = collect_scoped_tokens();
        saved_tokens* current_tokens = new saved_tokens;
        current_tokens.index = index;
        current_tokens.tokens = tokens;
        prev_state[prev_state_index] = current_tokens;
        tokens = scoped_tokens;
        index = 0;
        prev_state_index++;        
    }

    public void restore_previous_scope_level() {
        prev_state_index--;
        saved_tokens* restored_scope = prev_state[prev_state_index];
        prev_state[prev_state_index] = null;
        index = restored_scope.index;
        tokens = restored_scope.tokens;
    }

    public string[] collect_scoped_tokens() {
        while(has_tokens() && collector.not_done_collecting()) {
            collector.add_token(next_token());
        }
        return collector.get_scoped_tokens();
    }

    public void display_tokens() {
        foreach(string tok; tokens) {
            writeln(tok);
        }
    }


    private void check_files(string[] arguments) {
        import std.algorithm: endsWith;
        import core.sys.posix.stdlib: exit;
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
            tokenize(rawline);
        }
    }

    private void tokenize(string stream) {
        string trailing;
        string leading;
        foreach(char ch; stream) {
            trailing = "" ~ ch;
            if(is_part_of_valid_token(trailing)) {
                if(is_partial_op(candidate)) {
                    add_candidate();
                }
                candidate ~= trailing;
            } else if(is_partial_op(trailing)) {
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
        if(is_valid_variable(candidate ~ part)) {
            return true;
        } else if(is_keyword(candidate ~ part)) {
            return true;
        } else if(is_number(part)) {
            return true;
        }  else if(is_dot(part)) {
            return true;
        } else {
            return false;
        }
    }

    private void tokenize_partial_ops(string part) {
        if(candidate.length < 1) {
            candidate = part;
        } else if(is_operator(candidate ~ part) ) {
            candidate ~= part;
            add_candidate();
        } else if(is_assignment(candidate ~ part)) {
            candidate ~= part;
            add_candidate();
        } else if(is_partial_op(candidate)) {
            add_candidate();
        } else {
            add_candidate();
            candidate ~= part;
        }
    }

    private void determine_token_type(string type) {
        if(is_terminator(type) ||
           is_operator(type)   ||
           is_seperator(type))
        {
            candidate = type;
            add_candidate();
        } else if(is_partial_op(type)) {
            candidate = type;
        } else if(is_valid_variable(type)) {
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
}













unittest {
    Lexer l = new Lexer();
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
    Lexer l = new Lexer();
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
    Lexer l = new Lexer();
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
    Lexer l = new Lexer();
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

unittest {
    string test = "inty booly floaty fny breakr 
             returnn whiley continueo";
    Lexer l = new Lexer(test);

    string[] expect = ["inty", "booly", "floaty", "fny",
              "breakr", "returnn", "whiley","continueo"];
    
    assert(l.tokens.length == expect.length);
    for(int i = 0; i < expect.length; i++) {
        assert(l.next_token() == expect[i]);
    } 
}