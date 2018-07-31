module semantic_errors;
import core.sys.posix.stdlib: exit;
import std.stdio: writeln;

void invalid_func_call() {
    writeln("ERROR: invalid function call.");
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

void main_has_args() {
    writeln("ERROR: program entry point \"main\" cannot have arguments.");
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

void re_instantiation_of_variable() {
    writeln("ERROR: variable has already been declared.");
    exit(1);
}

void variable_type_mismatch() {
    writeln("ERROR: r value of variable assignment has mismatching types.");
    exit(1);
}

void variables_in_r_value_mismatch() {
    writeln("ERROR: expression in conditional or r values has mismatched types.");
    exit(1);
}

void variable_has_fn_name() {
    writeln("ERROR: cannot name variables with function names.");
    exit(1);
}

void assignment_to_constant() {
    writeln("ERROR: cannot assign values to constants.");
    exit(1);
}

void assignment_to_keyword() {
    writeln("ERROR: cannot assign to keywords");
    exit(1);
}

void loop_escape_not_in_loop() {
    writeln("ERROR: break or continue not in a loop.");
    exit(1);
}

void return_statement_has_no_value() {
    writeln("ERROR: return statement resolves to void in a non void function.");
    exit(1);
}

void returning_values_in_void_function() {
    writeln("ERROR: return statement has values in a void function.");
    exit(1);
}

void non_void_func_missing_returns() {
    writeln("ERROR: non void function does not return value along all return paths.");
    exit(1);
}

void if_stmt_args_do_not_resolve_to_bool_value() {
    writeln("ERROR: branching logics argument does not resolve to bool value.");
    exit(1);
}

void loop_args_do_not_resolve_to_bool_value() {
    writeln("ERROR: loop logic argument does not resolve to bool value.");
    exit(1);
}

void call_to_non_existant_function() {
    writeln("ERROR: call to non existant function.");
    exit(1);
}

void incorrect_number_of_args_to_function() {
    writeln("ERROR: number of arguments in function call does not match function declaration.");
    exit(1);
}

void mismatching_function_argument() {
    writeln("ERROR: function call has mismatched arguments to function declaration.");
    exit(1);
}

void expressions_have_mismatching_types() {
    writeln("ERROR: assignment or return expression has type that does not match expected.");
    exit(1);
}

void undeclared_variables_in_expression() {
    writeln("ERROR: undeclared variable found in expression.");
    exit(1);
}