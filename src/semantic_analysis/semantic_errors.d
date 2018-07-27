module semantic_errors;
import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void invalid_func_call() {
    writeln("ERROR: call to non existant function.");
    exit(1);
}

void calling_main() {
    writeln("ERROR: function \"main\" cannot be called by another function.");
    exit(1);
}

void missing_main() {
    writeln("ERROR: program must have exactly one entry function named main.");
    exit(1);
}

void orphaned_else_statement() {
    writeln("ERROR: else (if) statements must be preceded by an (else) if statement.");
    exit(1);
}

void loop_logic_creating_dead_code() {
    writeln("ERROR: break or continue statement creates unreachable code.");
    exit(1);
}

void return_creating_dead_code() {
    writeln("ERROR: return statement creates unreachable code.");
    exit(1);
}