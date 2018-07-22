module general_syntax_errors;
import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void statement_not_terminated() {
    writeln("ERROR: assignment statement not correctly terminated.");
    exit(1);
}

void invalid_statement() {
    writeln("ERROR: statement is not valid.");
    exit(1);
}