module general_syntax_errors;
import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void invalid_statement() {
    writeln("ERROR: statement is not valid.");
    exit(1);
}

void statement_not_terminated() {
    writeln("ERROR: Statement is not terminated.");
    exit(1);
}

void empty_print() {
    writeln("ERROR: Print statement contains no arguments.");
    exit(1);
}