module expression_errors;

import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void missing_arg_from_call() {
    writeln("ERROR: function call missing argument(s).");
    exit(1);
}