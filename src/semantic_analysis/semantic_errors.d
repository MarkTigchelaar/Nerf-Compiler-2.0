module semantic_errors;
import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void invalid_func_call() {
    writeln("ERROR: call to non existant function.");
    exit(1);
}