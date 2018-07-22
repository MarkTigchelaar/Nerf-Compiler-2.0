module variable_assign_errors;

import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void missing_assignment_operator() {
    writeln("ERROR: missing assignment operator.");
    exit(1);
}

void missing_r_value() {
    writeln("ERROR: statement is missing value for assignment / return.");
    exit(1);
}

void missing_identifier() {
    writeln("ERROR: assignment statement is missing identifier (L value).");
    exit(1);
}

void invalid_l_value() {
    writeln("ERROR: identifier cannot be a keyword or contain non alphbetical characters (underscore is exception).");
    exit(1);
}

void invalid_misspelt_type() {
    writeln("ERROR: invalid or misspelt type in assignment statement.");
    exit(1);
}

void assignment_to_constant() {
    writeln("ERROR: cannot assign to constant values.");
    exit(1);
}