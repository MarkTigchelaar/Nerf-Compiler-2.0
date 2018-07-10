module syntax_errors;
import core.sys.posix.stdlib: exit;
import std.stdio: writeln, write;

void no_fn_keyword() {
    writeln("ERROR: function declaration invalid.");
    exit(-1);
}

void no_fn_name() {
    writeln("ERROR: function missing name.");
    exit(-1);
}