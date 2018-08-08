module scoped_token_collector;

import stack;
import symbol_table;

class ScopedTokenCollector {
    private Stack!string stk;
    private SymbolTable table;
    private string[] scoped_tokens;
    private bool skip_token = true;

    this(SymbolTable table) {
        stk = new Stack!string;
        this.table = table;
    }

    public bool not_done_collecting() {
        return !stk.isEmpty();
    }

    public void add_token(string token) {
        if(!skip_token && stk.isEmpty()) {
            return;
        }
        if(table.is_open_seperator(token)) {
            stk.push(token);
        } else if(table.is_close_seperator(token)) {
            if(stk.peek() == table.get_close_match(token)) {
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
        skip_token = true;
        string[] temp = scoped_tokens.dup;
        scoped_tokens = null;
        return temp;
    }
}





unittest {
    SymbolTable s = new SymbolTable;
    ScopedTokenCollector sc = new ScopedTokenCollector(s);
    string[] expect = ["(", "i", "<", "j", ")"];
    foreach(string str; expect) {
        sc.add_token(str);
    }
    string[] result = sc.get_scoped_tokens();
    assert(expect.length == (result.length + 2));
    foreach(int i, string str; expect[1..4]) {
        assert(result[i] == str);
    }
    assert(sc.stk.isEmpty());
}

unittest {
    SymbolTable s = new SymbolTable;
    ScopedTokenCollector sc = new ScopedTokenCollector(s);
    string[] expect = ["(", "i", "<", "j", ")", "{", "}"];
    foreach(string str; expect) {
        sc.add_token(str);
    }
    string[] result = sc.get_scoped_tokens();
    assert(result.length == 3);
    foreach(int i, string str; expect[1..4]) {
        assert(result[i] == str);
    }
    assert(sc.stk.isEmpty());
}