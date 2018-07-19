module variable_assign_errors;

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
    writeln("ERROR: statement is missing value for assignment / return.");
    exit(1);
}