module branching_logic_errors;

import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void invalid_branching_logic_scope_token() {
    writeln("ERROR: body of branching logic statement begins with invalid token.");
    exit(1);
}

void invalid_args_token() {
    writeln("ERROR: branching logic arguments must be enclosed by parentheses.");
    exit(1);
}

void empty_statement_body() {
    writeln("ERROR: no statements in branching logic body.");
}

void empty_conditional() {
    writeln("ERROR: conditional is empty.");
    exit(1);
}