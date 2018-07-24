module expression_errors;

import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void missing_arg_from_call() {
    writeln("ERROR: function call missing argument(s).");
    exit(1);
}

void empty_parens() {
    writeln("ERROR: parenthesis contains no epressions.");
    exit(1);
}

void invalid_expression_token() {
    writeln("ERROR: token found in expression is invalid.");
    exit(1);
}

void multiple_minus_signs() {
    writeln("ERROR: expression has multiple - operators in sequence.");
    exit(1);
}

void invalid_expression() {
    writeln("ERROR: expression is invalid.");
    exit(1);
}