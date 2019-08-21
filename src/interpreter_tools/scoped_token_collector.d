module scoped_token_collector;

import stack;
import NewSymbolTable;

class ScopedTokenCollector {
    private Stack!string stk;
    private string[] scoped_tokens;
    private bool skip_token = true;

    this() {
        stk = new Stack!string;
    }

    public bool not_done_collecting() {
        return !stk.isEmpty();
    }

    public void add_token(string token) {
        if(!skip_token && stk.isEmpty()) {
            return;
        }
        if(is_open_seperator(token)) {
            stk.push(token);
        } else if(is_close_seperator(token)) {
            if(stk.peek() == get_close_match(token)) {
                stk.pop();
                if(stk.isEmpty()) {
                    return;
                }
            } else {
                throw new Exception(
                "bracket matching gone wrong, incorrect starting token?");
            }
        }
        if(!skip_token) {
            scoped_tokens ~= token;
        }
        skip_token = false;
    }

    public string[] get_scoped_tokens() {
        import std.stdio:writeln;
        skip_token = true;
        string[] temp = scoped_tokens.dup;
        scoped_tokens = null;
        return temp;
    }
}





unittest {
    ScopedTokenCollector sc = new ScopedTokenCollector();
    string[] expect = ["(", "i", "<", "j", ")"];
    foreach(string str; expect) {
        sc.add_token(str);
    }
    string[] result = sc.get_scoped_tokens();
    assert(expect.length == (result.length + 2));
    foreach(long i, string str; expect[1..4]) {
        assert(result[i] == str);
    }
    assert(sc.stk.isEmpty());
}

unittest {
    ScopedTokenCollector sc = new ScopedTokenCollector();
    string[] expect = ["(", "i", "<", "j", ")", "{", "}"];
    foreach(string str; expect) {
        sc.add_token(str);
    }
    string[] result = sc.get_scoped_tokens();
    assert(result.length == 3);
    foreach(long i, string str; expect[1..4]) {
        assert(result[i] == str);
    }
    assert(sc.stk.isEmpty());
}