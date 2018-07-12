module syntax_errors;
import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void no_void_keyword() {
    writeln("ERROR: function declaration invalid.");
    exit(1);
}

void no_void_name() {
    writeln("ERROR: function missing name.");
    exit(1);
}

void no_type_for_new_variable() {
    writeln("ERROR: variable not assigned a type.");
    exit(1);
} 

void no_value_on_instantiation() {
    writeln("ERROR: new variables must be instantiated with values.");
    exit(1);
}

void missing_assignment_operator() {
    writeln("ERROR: missing assignment operator.");
    exit(1);
}

void missing_r_value() {
    writeln();
    exit(1);
}

void orphaned_else_statement() {
    writeln("ERROR: else (if) statement must appear after if statement");
    exit(1);
}