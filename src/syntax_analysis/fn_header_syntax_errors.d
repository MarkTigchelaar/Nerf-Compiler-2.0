module fn_header_syntax_errors;

import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void no_fn_keyword() {
    writeln("ERROR: function declaration invalid.");
    exit(1);
}

void no_fn_name() {
    writeln("ERROR: function missing name.");
    exit(1);
}

void invalid_identifier_name() {
    writeln("ERROR: variable or function name has invalid characters.");
    exit(1);
}

void function_missing_arg_parens() {
    writeln("ERROR: function missing parentheses for arguments.");
    exit(1);
}

void fn_args_missing_or_invalid_type() {
    writeln("ERROR: function arguments(s) contain missing or invalid type(s).");
    exit(1);
}

void duplicate_fn_args() {
    writeln("ERROR: function has duplicate argument variable names.");
    exit(1);
}

void malformed_args() {
    writeln("ERROR: function arguments malformed");
    exit(1);
}

void duplicate_fn_name() {
    writeln("ERROR: functions must have unique names.");
    exit(1);
}

void missing_or_invalid_return_type() {
    writeln("ERROR: missing or invalid return type.");
    exit(1);
}

void missing_or_invalid_function_body_start_token() {
    writeln("ERROR: function body begins with invalid token.");
    exit(1);
}

void empty_func_body() {
    writeln("ERROR: function body is missing.");
    exit(1);
}

void unknown_type() {
    writeln("ERROR: unknown type declaration.");
    exit(1);
}